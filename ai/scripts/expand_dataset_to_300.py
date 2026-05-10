"""
Expand community_action_dataset.csv toward ~300 rows (150 post / 150 help).
Run from ai/:  python scripts/expand_dataset_to_300.py
"""
from __future__ import annotations

import csv
import sys
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = ROOT / "data" / "community_action_dataset.csv"

VALID_INPUT_HINTS = [
    "keyboard",
    "voice",
    "headEyes",
    "vibration",
    "deafBlind",
    "caregiver",
    "text",
    "tap",
    "haptic",
    "volume_shortcut",
]

POST_MODES = ["keyboard", "voice", "headEyes", "vibration", "deafBlind", "caregiver"]


def _bf(x: bool) -> str:
    return "true" if x else "false"


def gen_post_rows(n: int) -> list[dict]:
    scenarios: list[tuple[str, str, str, str, str]] = [
        ("obstacle trottoir casse ya pierres", "signalement", "motor", "medium", "precise"),
        ("pas de rampe fi entree mosque", "signalement", "motor", "medium", "precise"),
        ("escalier sans main courante danger", "alerte", "all", "critical", "precise"),
        ("mriguel escaliers mouilles attention", "alerte", "all", "critical", "precise"),
        ("sans rampe impossible monter avec fauteuil", "signalement", "motor", "medium", "approximate"),
        ("entree commerce seuil trop haut", "signalement", "motor", "medium", "precise"),
        ("porte automatique pane reste fermee", "signalement", "all", "medium", "precise"),
        ("acces difficile trottoir etroit", "signalement", "motor", "low", "approximate"),
        ("info ascenseur PMR ok ce matin", "information", "all", "none", "approximate"),
        ("conseil pour traverser avec canne blanche", "conseil", "visual", "low", "none"),
        ("temoignage personnel accueil tres correct", "temoignage", "all", "none", "none"),
        ("alerte nid poule devant ecole", "alerte", "all", "critical", "precise"),
        ("je veux publier photo du passage bloque", "signalement", "all", "medium", "precise"),
        ("jve poster une photo rampe cassee", "signalement", "motor", "medium", "precise"),
        ("je veux signaler un obstacle ya barriere", "signalement", "motor", "medium", "precise"),
        ("publication pour mon ami en fauteuil info acces", "information", "motor", "none", "approximate"),
        ("publier pour une autre personne besoin info guichet", "information", "caregiver", "none", "approximate"),
        ("bklé trottoir ya travaux", "signalement", "motor", "medium", "approximate"),
        ("jarrive pas monter marche trottoir", "signalement", "motor", "medium", "precise"),
        ("pas acces ascenseur en panne", "signalement", "motor", "medium", "approximate"),
        ("ya escalier raide sans balustrade", "alerte", "all", "critical", "precise"),
        ("obstacle chantier barriere mal placee", "signalement", "all", "medium", "precise"),
        ("info parking handicape plein alternative", "information", "motor", "none", "approximate"),
        ("conseil demander aide aux agents en gare", "conseil", "cognitive", "low", "none"),
        ("temoignage douche adaptee hotel nickel", "temoignage", "motor", "none", "none"),
        ("alerte fuite eau glissante devant banque", "alerte", "all", "critical", "precise"),
        ("signalement feu tricolore rapide pour pietons", "signalement", "visual", "medium", "precise"),
        ("information toilettes accessibles ouvertes tard", "information", "all", "none", "approximate"),
        ("conseil utiliser application pour itineraire accessible", "conseil", "all", "low", "none"),
        ("temoignage restaurant table basse ok", "temoignage", "motor", "none", "none"),
        ("alerte cable au sol zone chantier", "alerte", "all", "critical", "precise"),
        ("rampe trop raide pour manuel wheelchair", "signalement", "motor", "medium", "precise"),
        ("entree principale avec marche unique", "signalement", "motor", "low", "precise"),
        ("affiche braille absent guichet", "signalement", "visual", "low", "precise"),
        ("info ligne bus sur leve inclinaison ok", "information", "motor", "none", "approximate"),
        ("conseil anticiper les heures de pointe", "conseil", "cognitive", "low", "none"),
        ("temoignage personnel aimable traduction LSF", "temoignage", "hearing", "none", "none"),
        ("alerte chute branchage arbre sur trottoir", "alerte", "all", "critical", "precise"),
        ("passage etroit deux fauteuils impossible", "signalement", "motor", "medium", "approximate"),
        ("ascenseur trop petit pour fauteuil electrique", "signalement", "motor", "medium", "precise"),
        ("bouton appel ascenseur trop haut", "signalement", "motor", "medium", "precise"),
        ("info carte tactile disponible a laccueil", "information", "visual", "none", "approximate"),
        ("conseil garder lampe frontale la nuit", "conseil", "visual", "low", "none"),
        ("temoignage horaires respectes rdv medical", "temoignage", "all", "none", "none"),
        ("alerte circulation sens unique dangereux", "alerte", "all", "medium", "precise"),
        ("je veux publier alerte trottoir detruit", "alerte", "all", "critical", "precise"),
        ("photo du passage etroit entre deux murs", "signalement", "motor", "medium", "precise"),
        ("svp publier info utile pour handicapes moteur", "information", "motor", "none", "approximate"),
        ("urgent info fermeture rampe provisoire", "information", "motor", "none", "approximate"),
        ("svp poliment signaler obstacle temporaire", "signalement", "all", "low", "approximate"),
        ("mes respects je signale nid poule profond", "signalement", "motor", "medium", "precise"),
        ("ya pas acces ya seulement des marches", "signalement", "motor", "medium", "precise"),
        ("trottoir impraticable personne age assistante", "signalement", "motor", "medium", "approximate"),
        ("info utile pour tous les usagers PMR", "information", "all", "none", "approximate"),
        ("conseil prudence pluie surface glissante", "conseil", "all", "low", "none"),
        ("temoignage personnel tres satisfait equipe", "temoignage", "all", "none", "none"),
        ("alerte danger immediat fil electrique au sol", "alerte", "all", "critical", "precise"),
        ("signalement long detaille sur trace sans guidage", "signalement", "visual", "medium", "precise"),
        (
            "information detaillee horaires et acces PMR semaine prochaine",
            "information",
            "motor",
            "none",
            "approximate",
        ),
        ("obstacle metalique depasse ya risque blessure", "signalement", "all", "medium", "precise"),
        ("escalier mecanique arrete mi parcours", "signalement", "motor", "medium", "precise"),
        ("pas de bande podotactile au carrefour", "signalement", "visual", "medium", "precise"),
        ("entree laterale fermee cle manque", "signalement", "all", "medium", "precise"),
        ("acces pente trop forte pour accompagnateur", "signalement", "motor", "medium", "approximate"),
        ("info balisage sonore operationnel", "information", "visual", "none", "approximate"),
        ("conseil arrivez tot pour eviter cohue", "conseil", "cognitive", "low", "none"),
        ("temoignage experience mitigee personnel peu forme", "temoignage", "all", "none", "none"),
        ("alerte verglas matinal trottoir hopital", "alerte", "all", "critical", "precise"),
        ("signalement quai train ecart trop large", "signalement", "motor", "medium", "precise"),
        ("je veux poster une photo de la barriere", "signalement", "motor", "medium", "precise"),
        ("je veux publier pour informer les usagers", "information", "all", "none", "approximate"),
        ("publier photo souci signalisation", "signalement", "visual", "medium", "precise"),
        ("obstacle temporaire cone renverse", "signalement", "all", "medium", "approximate"),
        ("marches sans contraste visuel", "signalement", "visual", "medium", "precise"),
        ("largeur porte insuffisante fauteuil", "signalement", "motor", "medium", "precise"),
        ("wc adapte mais poignee cassee", "signalement", "motor", "medium", "precise"),
        ("info navette gratuite pour PMR weekend", "information", "motor", "none", "approximate"),
        ("conseil telephoner avant pour reserver place", "conseil", "motor", "low", "none"),
        ("temoignage bruit excessif sal dattente", "temoignage", "hearing", "none", "none"),
        ("alerte eclairage public eteint ruelle", "alerte", "all", "critical", "precise"),
        ("signalement vitre sale difficile visibilite", "signalement", "visual", "low", "precise"),
        ("information sens unique pieton modifie", "information", "all", "none", "approximate"),
        ("conseil preferer entree nord moins de marches", "conseil", "motor", "low", "none"),
        ("temoignage accompagnement benevole super", "temoignage", "all", "none", "none"),
        ("alerte flaque huile zone parking", "alerte", "all", "critical", "precise"),
        ("obstacle volontaire barriere chantier", "signalement", "all", "medium", "precise"),
        ("escalier interieur sans ascenseur alternatif", "signalement", "motor", "medium", "precise"),
        ("jarrive pas comprendre ou est lentree PMR", "information", "motor", "none", "approximate"),
        ("bkle je reste coince devant barriere", "signalement", "motor", "medium", "precise"),
        ("je sui perdu dans couloir hopital signalement access", "information", "all", "none", "approximate"),
        ("je suis perdu pres sortie secours info", "information", "all", "none", "approximate"),
        ("mrigel ya trop de monde orientation compliquee info", "information", "cognitive", "none", "approximate"),
        ("svp urgent publier danger trottoir effondre", "alerte", "all", "critical", "precise"),
        ("photo pour montrer largeur passage", "signalement", "motor", "medium", "precise"),
        ("pour ma mere en fauteuil info sur acces", "information", "motor", "none", "approximate"),
        ("publication pour autrui besoin conseil acces", "conseil", "caregiver", "low", "none"),
    ]

    rows: list[dict] = []
    for i in range(n):
        text_core, nature, aud, dang, loc = scenarios[i % len(scenarios)]
        if i >= len(scenarios):
            text_core = f"{text_core} (var {i})"
        hint = VALID_INPUT_HINTS[i % len(VALID_INPUT_HINTS)]
        mode = POST_MODES[i % len(POST_MODES)]
        needs_audio = nature == "signalement" and aud == "visual"
        needs_vis = aud == "visual" or "visibilite" in text_core.lower()
        needs_phys = aud == "motor" or "fauteuil" in text_core.lower()
        needs_simple = aud == "cognitive" or i % 4 == 0
        for_another = aud == "caregiver" and i % 2 == 0
        rows.append(
            {
                "text": text_core[:500],
                "inputModeHint": hint,
                "isForAnotherPersonHint": _bf(for_another),
                "actionType": "create_post",
                "postNature": nature,
                "targetAudience": aud,
                "postInputMode": mode,
                "locationSharingMode": loc,
                "dangerLevel": dang,
                "helpType": "none",
                "requesterProfile": "none",
                "helpInputMode": "none",
                "presetMessageKey": "none",
                "needsAudioGuidance": _bf(needs_audio),
                "needsVisualSupport": _bf(needs_vis),
                "needsPhysicalAssistance": _bf(needs_phys),
                "needsSimpleLanguage": _bf(needs_simple),
                "isForAnotherPerson": _bf(for_another),
            }
        )
    return rows


def gen_help_rows(n: int) -> list[dict]:
    scenarios: list[tuple[str, str, str, str, str]] = [
        ("je suis perdu pres la porte sud", "orientation", "visual", "voice", "lost"),
        ("je sui perdu ya pas de panneau", "orientation", "unknown", "text", "lost"),
        ("jarrive pas trouver la sortie PMR", "orientation", "motor", "voice", "lost"),
        ("perdu dans parking niveau moins un", "orientation", "unknown", "tap", "lost"),
        ("bkle devant grille je peux pas passer", "mobility", "motor", "text", "blocked"),
        ("mobilite bloquee ya trop de marches", "mobility", "motor", "haptic", "blocked"),
        ("pas acces ya barriere electrique", "unsafe_access", "motor", "voice", "blocked"),
        ("acces dangereux trottoir effondre", "unsafe_access", "unknown", "text", "blocked"),
        ("communication urgent besoin interprete", "communication", "hearing", "caregiver", "cannot_reach"),
        ("jarrive pas expliquer douleur au guichet", "communication", "cognitive", "text", "cannot_reach"),
        ("urgence medicale essoufflement fort", "medical", "unknown", "voice", "medical_urgent"),
        ("urgent svp malaise vertige", "medical", "unknown", "volume_shortcut", "medical_urgent"),
        ("besoin accompagnement jusquau taxi", "escort", "cognitive", "voice", "escort"),
        ("escort pour personne agee peur foule", "escort", "caregiver", "caregiver", "escort"),
        ("pour ma tante aide mobilite ascenseur", "mobility", "caregiver", "text", "cannot_reach"),
        ("caregiver demande aide pour patient", "mobility", "caregiver", "caregiver", "cannot_reach"),
        ("aide svp vite coince sous marquise", "mobility", "motor", "text", "blocked"),
        ("aide rapide besoin orientation gare", "orientation", "visual", "tap", "lost"),
        ("simple je suis perdu aidez moi", "orientation", "cognitive", "text", "lost"),
        ("besoin langage simple guichet", "communication", "cognitive", "voice", "cannot_reach"),
        ("guidage vocal pour sortie accessible", "orientation", "visual", "voice", "lost"),
        ("yeux fatigue besoin contrast eleve", "orientation", "visual", "text", "lost"),
        ("mrigel ou est la rampe ya confusion", "orientation", "unknown", "haptic", "lost"),
        ("unsafe passage nuit sans eclairage", "unsafe_access", "unknown", "voice", "blocked"),
        ("other probleme non liste urgence legere", "other", "unknown", "text", "none"),
        ("je suis perdu entre deux batiments", "orientation", "unknown", "text", "lost"),
        ("mobilite urgence fauteuil coince porte", "mobility", "motor", "voice", "blocked"),
        ("communication SLS besoin urgent", "communication", "hearing", "tap", "cannot_reach"),
        ("medical urgent douleur thoracique", "medical", "unknown", "voice", "medical_urgent"),
        ("escort needed pour traverser grande avenue", "escort", "visual", "voice", "escort"),
        ("svp orientation ya bruit je comprends pas", "orientation", "hearing", "voice", "lost"),
        ("jarrive pas lire le plan besoin aide", "orientation", "visual", "text", "lost"),
        ("coince trottoir etroit avec deux cannes", "mobility", "motor", "haptic", "blocked"),
        ("entree principale bloquee par voiture", "unsafe_access", "motor", "text", "blocked"),
        ("besoin parler lentement au standard", "communication", "hearing", "voice", "cannot_reach"),
        ("crise sucre besoin assistance medicale", "medical", "unknown", "tap", "medical_urgent"),
        ("raccompagnement jusqua billetterie", "escort", "motor", "caregiver", "escort"),
        ("pour autrui demande escort urgence", "escort", "caregiver", "caregiver", "escort"),
        ("urgent svp jarrive pas respirer bien", "medical", "unknown", "voice", "medical_urgent"),
        ("aide svp rapide orientation sortie metro", "orientation", "unknown", "volume_shortcut", "lost"),
        ("pas acces ya fosse travaux", "unsafe_access", "motor", "text", "blocked"),
        ("communication ecriture grand caractere", "communication", "visual", "text", "cannot_reach"),
        ("guidage visuel ligne au sol manquante", "orientation", "visual", "voice", "lost"),
        ("simple phrase besoin aide maintenant", "mobility", "cognitive", "text", "blocked"),
        ("aide svp urgent jarrive pas monter", "mobility", "motor", "voice", "blocked"),
        ("je suis perdu entre deux quais gare", "orientation", "unknown", "text", "lost"),
        ("orientation rapide svp je suis stresse", "orientation", "cognitive", "haptic", "lost"),
        ("mobilite jarrive pas franchir seuil", "mobility", "motor", "tap", "cannot_reach"),
        ("unsafe_access entree glissante pluie", "unsafe_access", "motor", "voice", "blocked"),
        ("communication besoin relais ecrit guichet", "communication", "hearing", "text", "cannot_reach"),
        ("medical urgence fatigue extreme", "medical", "unknown", "voice", "medical_urgent"),
        ("escort pour traverser passage souterrain", "escort", "visual", "voice", "escort"),
        ("pour personne accompagnee besoin aide rapide", "mobility", "caregiver", "caregiver", "cannot_reach"),
        ("caregiver: mon pere tombe souvent besoin escort", "escort", "caregiver", "caregiver", "escort"),
        ("besoin phrases simples urgence administrative", "communication", "cognitive", "text", "cannot_reach"),
        ("guidage pas a pas audio vers sortie", "orientation", "visual", "voice", "lost"),
        ("besoin contraste fort pour lire panneau", "orientation", "visual", "text", "lost"),
        ("mrigel ya denivelé jarrive pas", "mobility", "motor", "haptic", "blocked"),
        ("urgent aide svp coince ascenseur", "mobility", "motor", "volume_shortcut", "blocked"),
        ("pas acces trottoir barre chantier long", "unsafe_access", "motor", "text", "blocked"),
        ("communication impossible telephone bruyant", "communication", "hearing", "tap", "cannot_reach"),
        ("medical signaler vertiges violents", "medical", "unknown", "voice", "medical_urgent"),
        ("escort needed pour elderly slow walker", "escort", "motor", "caregiver", "escort"),
        ("other demande mineure orientation hall", "other", "unknown", "text", "none"),
    ]

    rows: list[dict] = []
    for i in range(n):
        text_t, ht, rp, hm, pk = scenarios[i % len(scenarios)]
        if i >= len(scenarios):
            text_t = f"{text_t} (var {i})"
        hint = VALID_INPUT_HINTS[i % len(VALID_INPUT_HINTS)]
        na = ht == "orientation" and rp == "visual"
        nv = rp == "visual"
        np = rp == "motor"
        ns = rp == "cognitive" or i % 3 == 0
        for_another = rp == "caregiver" and i % 2 == 0
        rows.append(
            {
                "text": text_t[:500],
                "inputModeHint": hint,
                "isForAnotherPersonHint": _bf(for_another),
                "actionType": "create_help_request",
                "postNature": "none",
                "targetAudience": "none",
                "postInputMode": "none",
                "locationSharingMode": "none",
                "dangerLevel": "none",
                "helpType": ht,
                "requesterProfile": rp,
                "helpInputMode": hm,
                "presetMessageKey": pk,
                "needsAudioGuidance": _bf(na),
                "needsVisualSupport": _bf(nv),
                "needsPhysicalAssistance": _bf(np),
                "needsSimpleLanguage": _bf(ns),
                "isForAnotherPerson": _bf(for_another),
            }
        )
    return rows


def main() -> int:
    if not DATA_PATH.exists():
        print(f"Missing {DATA_PATH}", file=sys.stderr)
        return 2

    df = pd.read_csv(DATA_PATH)

    bad = df["inputModeHint"].astype(str).str.lower() == "lost"
    if bad.any():
        df.loc[bad, "inputModeHint"] = "text"

    target_each = 150
    post_n = int((df["actionType"] == "create_post").sum())
    help_n = int((df["actionType"] == "create_help_request").sum())
    need_post = max(0, target_each - post_n)
    need_help = max(0, target_each - help_n)

    out = pd.concat(
        [df, pd.DataFrame(gen_post_rows(need_post)), pd.DataFrame(gen_help_rows(need_help))],
        ignore_index=True,
    )

    out["_t"] = out["text"].astype(str).str.strip().str.lower()
    out = out.drop_duplicates(subset=["_t"], keep="first").drop(columns=["_t"])

    for _ in range(10):
        pc = int((out["actionType"] == "create_post").sum())
        hc = int((out["actionType"] == "create_help_request").sum())
        if pc >= target_each and hc >= target_each:
            break
        if pc < target_each:
            out = pd.concat([out, pd.DataFrame(gen_post_rows(target_each - pc))], ignore_index=True)
        if hc < target_each:
            out = pd.concat([out, pd.DataFrame(gen_help_rows(target_each - hc))], ignore_index=True)
        out["_t"] = out["text"].astype(str).str.strip().str.lower()
        out = out.drop_duplicates(subset=["_t"], keep="first").drop(columns=["_t"])

    out.to_csv(
        DATA_PATH,
        index=False,
        quoting=csv.QUOTE_ALL,
        lineterminator="\n",
        encoding="utf-8",
    )

    pf = int((out["actionType"] == "create_post").sum())
    hf = int((out["actionType"] == "create_help_request").sum())
    print(f"Wrote {DATA_PATH}")
    print(f"Total rows: {len(out)}")
    print(f"create_post: {pf}")
    print(f"create_help_request: {hf}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
