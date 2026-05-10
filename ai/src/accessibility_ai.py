"""
Analyse d'accessibilité des lieux (Groq + Overpass OSM), migré depuis backend_ia.
"""
from __future__ import annotations

import json
import os
from typing import List, Tuple

import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()

GROQ_API_KEY = os.environ.get("GROQ_API_KEY")
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_TEXT_MODEL = os.environ.get("GROQ_TEXT_MODEL", "llama-3.1-8b-instant")


class PlaceAnalysisRequest(BaseModel):
    place_name: str
    latitude: float
    longitude: float
    wheelchair_access: bool = False
    elevator: bool = False
    braille: bool = False
    audio_assistance: bool = False
    accessible_toilets: bool = False
    user_comments: list[str] = []
    has_community_data: bool = False
    community_posts_count: int = 0


class HandicapScore(BaseModel):
    score: int
    niveau: str
    details: list[str]
    sources: list[str]


class AccessibilityAnalysisResult(BaseModel):
    place_name: str
    score_global: int
    fauteuil_roulant: HandicapScore
    surdite: HandicapScore
    cecite: HandicapScore
    mobilite_reduite: HandicapScore
    cognitif: HandicapScore
    osm_tags: dict
    resume_ia: str
    confiance: str
    sources_utilisees: list[str]


async def groq_chat(prompt: str, max_tokens: int = 1200) -> str:
    if not GROQ_API_KEY:
        raise HTTPException(
            status_code=503,
            detail="GROQ_API_KEY manquant : définir la variable d'environnement.",
        )
    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": GROQ_TEXT_MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
        "temperature": 0.1,
    }
    async with httpx.AsyncClient(timeout=30.0) as client:
        r = await client.post(GROQ_URL, headers=headers, json=payload)
        if r.status_code != 200:
            raise HTTPException(
                status_code=500,
                detail=f"Groq error {r.status_code}: {r.text}",
            )
        return r.json()["choices"][0]["message"]["content"].strip()


def clean_json(raw: str) -> str:
    raw = raw.strip()
    if "```" in raw:
        parts = raw.split("```")
        for part in parts:
            if part.startswith("json"):
                raw = part[4:].strip()
                break
            elif "{" in part:
                raw = part.strip()
                break
    start = raw.find("{")
    end = raw.rfind("}") + 1
    if start != -1 and end > start:
        return raw[start:end]
    return raw


async def fetch_osm_accessibility(lat: float, lon: float, radius: int = 80) -> dict:
    query = f"""
    [out:json][timeout:10];
    (
      node(around:{radius},{lat},{lon});
      way(around:{radius},{lat},{lon});
    );
    out tags;
    """
    try:
        async with httpx.AsyncClient(timeout=20.0) as client:
            r = await client.post(
                "https://overpass-api.de/api/interpreter",
                data={"data": query},
            )
            r.raise_for_status()
            data = r.json()
    except Exception as e:
        print(f"[OSM] Overpass indisponible: {e}")
        return {}

    keywords = [
        "wheelchair",
        "ramp",
        "elevator",
        "lift",
        "tactile",
        "hearing",
        "braille",
        "blind",
        "accessible",
        "step",
        "kerb",
        "handrail",
        "disabled",
        "toilet",
        "pmr",
    ]
    merged = {}
    for element in data.get("elements", []):
        for key, value in element.get("tags", {}).items():
            if any(kw in key.lower() for kw in keywords):
                merged[key] = value
    return merged


def merge_data(request: PlaceAnalysisRequest, osm_tags: dict) -> dict:
    m3ak = {
        "wheelchair_access": request.wheelchair_access,
        "elevator": request.elevator,
        "braille": request.braille,
        "audio_assistance": request.audio_assistance,
        "accessible_toilets": request.accessible_toilets,
    }
    osm = {
        "wheelchair": osm_tags.get("wheelchair", "unknown"),
        "ramp": osm_tags.get("ramp") == "yes",
        "step_free": osm_tags.get("kerb") == "flush",
        "hearing_loop": osm_tags.get("hearing_loop") == "yes",
        "tactile_paving": osm_tags.get("tactile_paving") == "yes",
        "elevator_osm": osm_tags.get("elevator") == "yes",
        "has_osm_data": len(osm_tags) > 0,
    }
    return {"m3ak": m3ak, "osm": osm}


def _split_community_vs_other_comments(comments: list) -> Tuple[List[str], List[str]]:
    community: List[str] = []
    other: List[str] = []
    for c in comments or []:
        if isinstance(c, str) and c.strip().startswith("[Communauté M3ak"):
            community.append(c.strip())
        else:
            if isinstance(c, str) and c.strip():
                other.append(c.strip())
    return community, other


async def analyze_with_groq(
    place_name,
    comments,
    osm_tags,
    features,
    has_community_data: bool = False,
    community_posts_count: int = 0,
):
    m3ak = features.get("m3ak", {})
    osm = features.get("osm", {})
    community_lines, generic_lines = _split_community_vs_other_comments(comments)

    def fmt_community_line(line: str) -> str:
        inner = line
        if inner.startswith("[Communauté M3ak"):
            close = inner.find("]")
            if close != -1:
                tag = inner[: close + 1]
                body = inner[close + 1 :].strip()
                type_hint = tag
                return f"- {type_hint} → {body}"
        return f"- {line}"

    section_ma3ak = (
        "\n".join(fmt_community_line(x) for x in community_lines)
        if community_lines
        else "Aucun avis communauté fourni."
    )
    section_generic = (
        "\n".join(f"- {x}" for x in generic_lines)
        if generic_lines
        else "Aucun autre commentaire."
    )

    meta_community = (
        f"Indicateurs requête : has_community_data={has_community_data}, "
        f"community_posts_count={community_posts_count} (nombre d avis M3ak sélectionnés côté app)."
    )

    prompt = f"""Tu es un expert senior en accessibilité universelle et aux besoins des personnes en situation de handicap (PMR, déficience sensorielle, cognitive).
Tu analyses UN SEUL lieu identifié ci-dessous. Réponds en français.

=== LIEU ANALYSÉ ===
{place_name}

=== DONNÉES STRUCTURÉES APP M3AK (saisie utilisateur / profil) ===
- Fauteuil roulant déclaré : {'OUI' if m3ak.get('wheelchair_access') else 'NON'}
- Ascenseur déclaré : {'OUI' if m3ak.get('elevator') else 'NON'}
- Braille déclaré : {'OUI' if m3ak.get('braille') else 'NON'}
- Assistance audio déclarée : {'OUI' if m3ak.get('audio_assistance') else 'NON'}
- Toilettes accessibles déclarées : {'OUI' if m3ak.get('accessible_toilets') else 'NON'}

=== DONNÉES OSM (OpenStreetMap — contexte générique autour des coordonnées) ===
Ces tags sont souvent incomplets ou génériques ; utilise-les comme appoint, PAS comme vérité absolue.
- Rampe détectée (OSM) : {'OUI' if osm.get('ramp') else 'NON'}
- Revêtement tactile : {'OUI' if osm.get('tactile_paving') else 'NON'}
- Boucle à induction / hearing : {'OUI' if osm.get('hearing_loop') else 'NON'}
- Ascenseur (OSM) : {'OUI' if osm.get('elevator_osm') else 'NON'}
- Données OSM présentes : {'OUI' if osm.get('has_osm_data') else 'NON'}

=== AVIS COMMUNAUTÉ MA3AK (témoignages réels — priorité haute) ===
Chaque ligne indique le type de handicap concerné dans l entête [Communauté M3ak - …].
Ces retours terrain doivent peser PLUS lourd que les tags OSM génériques lorsqu ils décrivent un problème ou une qualité concrète sur CE lieu.
{section_ma3ak}

=== AUTRES COMMENTAIRES (hors préfixe communauté) ===
{section_generic}

=== MÉTA ===
{meta_community}

=== CONSIGNES DE NOTATION (obligatoires) ===
1) Pondération : donne une importance SUPÉRIEURE aux avis « AVIS COMMUNAUTÉ MA3AK » face aux seuls tags OSM.
2) Précision numérique : évite les scores « ronds » (ex. 50, 60, 70). Privilégie des scores nuancés (ex. 54, 63, 71) cohérents avec les preuves textuelles.
3) Justification : pour chaque axe (fauteuil, surdité, cécité, mobilité réduite, cognitif), les « details » doivent citer explicitement quelles données ont guidé la note (avis M3ak, OSM, ou données app).
4) Contradictions : si des avis positifs et négatifs coexistent, mentionne-le dans « resume_ia » et dans les « details » pertinents ; arbitrage prudent (date, gravité, récurrence décrite).
5) Sources : dans chaque HandicapScore, le champ « sources » peut inclure par ex. « Communauté M3ak », « OSM », « Saisie M3ak » selon ce qui a réellement influencé le score.

Retourne UNIQUEMENT un JSON valide (sans markdown), exactement de la forme :
{{
  "score_global": <0-100>,
  "fauteuil_roulant": {{"score":<0-100>,"niveau":"<Excellent|Bon|Partiel|Non adapté>","details":["..."],"sources":["..."]}},
  "surdite": {{"score":<0-100>,"niveau":"<Excellent|Bon|Partiel|Non adapté>","details":["..."],"sources":["..."]}},
  "cecite": {{"score":<0-100>,"niveau":"<Excellent|Bon|Partiel|Non adapté>","details":["..."],"sources":["..."]}},
  "mobilite_reduite": {{"score":<0-100>,"niveau":"<Excellent|Bon|Partiel|Non adapté>","details":["..."],"sources":["..."]}},
  "cognitif": {{"score":<0-100>,"niveau":"<Excellent|Bon|Partiel|Non adapté>","details":["..."],"sources":["..."]}},
  "resume_ia": "<paragraphe court, contradictions éventuelles>",
  "confiance": "<Élevée|Moyenne|Faible>",
  "sources_utilisees": ["..."]
}}"""

    raw = await groq_chat(prompt, max_tokens=1500)
    try:
        data = json.loads(clean_json(raw))
    except json.JSONDecodeError as e:
        raise HTTPException(
            status_code=502,
            detail=f"Réponse Groq non JSON exploitable: {e}",
        ) from e

    def to_score(d):
        return HandicapScore(
            score=int(d.get("score", 0)),
            niveau=d.get("niveau", "Non adapté"),
            details=d.get("details", []),
            sources=d.get("sources", []),
        )

    try:
        return AccessibilityAnalysisResult(
            place_name=place_name,
            score_global=int(data.get("score_global", 0)),
            fauteuil_roulant=to_score(data["fauteuil_roulant"]),
            surdite=to_score(data["surdite"]),
            cecite=to_score(data["cecite"]),
            mobilite_reduite=to_score(data["mobilite_reduite"]),
            cognitif=to_score(data["cognitif"]),
            osm_tags=osm_tags,
            resume_ia=data.get("resume_ia", ""),
            confiance=data.get("confiance", "Faible"),
            sources_utilisees=data.get("sources_utilisees", []),
        )
    except (KeyError, TypeError, ValueError) as e:
        raise HTTPException(
            status_code=502,
            detail=f"Structure JSON Groq incomplète: {e}",
        ) from e


@router.post("/analyze", response_model=AccessibilityAnalysisResult)
async def analyze_place(request: PlaceAnalysisRequest):
    osm_tags = await fetch_osm_accessibility(request.latitude, request.longitude)
    merged = merge_data(request, osm_tags)
    return await analyze_with_groq(
        request.place_name,
        request.user_comments,
        osm_tags,
        merged,
        has_community_data=request.has_community_data,
        community_posts_count=request.community_posts_count,
    )
