#!/usr/bin/env python3
"""
Seed MongoDB (ma3ak.posts) — avis communauté de démo pour l'analyse d'accessibilité.

À chaque exécution : suppression des documents seed (isSeed: true), puis réinsertion.

Usage (depuis la racine du repo ou cd ai) :
  python scripts/seed_posts.py

Variables : MONGODB_URI (défaut mongodb://127.0.0.1:27017/ma3ak), DB_NAME (défaut ma3ak).
"""
from __future__ import annotations

import os
import random
import sys
from datetime import datetime, timedelta

from bson import ObjectId
from pymongo import MongoClient

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if ROOT not in sys.path:
    sys.path.insert(0, ROOT)

try:
    from dotenv import load_dotenv

    load_dotenv(os.path.join(ROOT, ".env"))
except ImportError:
    pass

MONGO_URI = os.environ.get("MONGODB_URI", "mongodb://127.0.0.1:27017/ma3ak")
DB_NAME = os.environ.get("DB_NAME", "ma3ak")
COLLECTION = "posts"

FAKE_USER_ID = ObjectId("507f1f77bcf86cd799439011")


def _rand_recent_dt() -> datetime:
    days = random.randint(0, 45)
    hours = random.randint(0, 23)
    return datetime.utcnow() - timedelta(days=days, hours=hours)


PLACES: list[dict] = [
    {
        "placeId": "esprit",
        "placeName": "Université ESPRIT (Ariana)",
        "posts": [
            (
                "handicapMoteur",
                "à l'entrée principale, les rampes d'accès sont absentes : uniquement des marches, très difficile en fauteuil roulant.",
                "low",
            ),
            (
                "handicapMoteur",
                "dans le bâtiment B, un ascenseur permet de rejoindre les étages sans emprunter les escaliers.",
                "none",
            ),
            (
                "handicapVisuel",
                "les couloirs ne sont pas équipés de bandes podotactiles : difficile de repérer les obstacles au sol sans aide.",
                "low",
            ),
            (
                "handicapAuditif",
                "les annonces et informations ne sont pas affichées sur des écrans : en tant que personne sourde, je ne vois pas les messages.",
                "low",
            ),
            (
                "temoignage",
                "globalement, mon passage en fauteuil sur ce campus reste compliqué à cause des reliefs et du manque d'itinéraires pmr clairs.",
                "low",
            ),
            (
                "conseil",
                "je recommande de contacter l'administration avant une visite pour organiser un accès ou une rencontre dans un espace adapté.",
                "none",
            ),
        ],
    },
    {
        "placeId": "charles_nicolle",
        "placeName": "Hôpital Charles Nicolle (Tunis)",
        "posts": [
            (
                "handicapMoteur",
                "les couloirs principaux sont assez larges pour circuler en fauteuil, et du matériel est disponible sur demande.",
                "none",
            ),
            (
                "handicapMoteur",
                "l'ascenseur est souvent en panne : il faut prévoir un détour ou attendre très longtemps ; les couloirs restent larges mais l'accès reste compliqué.",
                "low",
            ),
            (
                "handicapVisuel",
                "le personnel m'a guidée jusqu'au bon service quand je ne voyais pas les panneaux : aide précieuse.",
                "none",
            ),
            (
                "handicapAuditif",
                "les informations passent surtout par la voix à l'accueil, sans affichage écrit ou écran : je ne peux pas les capter.",
                "low",
            ),
            (
                "temoignage",
                "l'équipe est bienveillante, mais les bâtiments sont vieillissants et l'accessibilité reste inégale selon les services.",
                "low",
            ),
            (
                "conseil",
                "pour les démarches administratives, mieux vaut venir accompagné pour gagner du temps entre les guichets.",
                "none",
            ),
        ],
    },
    {
        "placeId": "carrefour_la_marsa",
        "placeName": "Centre Commercial Carrefour La Marsa",
        "posts": [
            (
                "handicapMoteur",
                "parking PMR bien signalé et rampes disponibles à toutes les entrées ; les rampes d'accès sont présentes partout où j'ai circulé.",
                "none",
            ),
            (
                "handicapMoteur",
                "au sous-sol, les toilettes adaptées sont accessibles avec barres d'appui et espace de transfert.",
                "none",
            ),
            (
                "handicapVisuel",
                "les allées du magasin ne sont pas jalonnées de bandes podotactiles pour suivre un trajet sans vision.",
                "low",
            ),
            (
                "handicapAuditif",
                "les caisses affichent les montants et messages sur des écrans : je peux suivre l'information sans entendre.",
                "none",
            ),
            (
                "temoignage",
                "pour moi en fauteuil, c'est l'un des centres les plus confortables de la zone pour faire mes courses.",
                "none",
            ),
            (
                "conseil",
                "le week-end il y a beaucoup de monde : venez en semaine ou tôt le matin pour circuler plus facilement.",
                "none",
            ),
        ],
    },
    {
        "placeId": "aeroport_tunis_carthage",
        "placeName": "Aéroport Tunis-Carthage",
        "posts": [
            (
                "handicapMoteur",
                "l'assistance pmr est disponible si on la demande à l'avance, mais les files peuvent être longues.",
                "low",
            ),
            (
                "handicapMoteur",
                "les distances à parcourir dans le terminal sont importantes, avec peu de bancs pour se reposer en cours de route.",
                "low",
            ),
            (
                "handicapVisuel",
                "les annonces de vols sont diffusées en arabe et en français : j'arrive à suivre les informations par l'ouïe.",
                "none",
            ),
            (
                "handicapAuditif",
                "aux comptoirs d'enregistrement, pas de boucle magnétique pour mon appareil auditif : entendre le personnel reste difficile.",
                "low",
            ),
            (
                "temoignage",
                "le personnel fait de son mieux pour aider, mais l'infrastructure mériterait plus de cheminements plain-pied.",
                "low",
            ),
            (
                "conseil",
                "réservez l'assistance pmr au moins 48 heures avant le vol pour éviter l'attente et les imprévus.",
                "none",
            ),
        ],
    },
    {
        "placeId": "gare_tunis",
        "placeName": "Gare de Tunis",
        "posts": [
            (
                "handicapMoteur",
                "beaucoup de marches entre les quais et les passages : difficile de monter en fauteuil sans aide humaine.",
                "low",
            ),
            (
                "handicapMoteur",
                "les quais ne sont pas de plain-pied avec les trains : l'accès en fauteuil est très problématique.",
                "low",
            ),
            (
                "handicapVisuel",
                "aucune bande podotactile ne permet de se diriger seul vers le bon quai : il faut demander constamment de l'aide.",
                "low",
            ),
            (
                "handicapAuditif",
                "de grands écrans affichent les trains et retards : je peux lire les infos même si je n'entends pas les annonces.",
                "none",
            ),
            (
                "temoignage",
                "pour une personne à mobilité réduite, c'est vraiment éprouvant : j'évite d'y passer si j'ai une autre option.",
                "low",
            ),
            (
                "conseil",
                "quand c'est possible, privilégiez le métro léger ou des correspondances annoncées comme plus accessibles.",
                "none",
            ),
        ],
    },
    {
        "placeId": "musee_bardo",
        "placeName": "Musée du Bardo",
        "posts": [
            (
                "handicapMoteur",
                "la rampe à l'entrée principale permet de franchir le seuil sans porter le fauteuil.",
                "none",
            ),
            (
                "handicapMoteur",
                "certaines salles d'exposition restent inaccessibles à cause d'escaliers ou de seuils trop hauts.",
                "low",
            ),
            (
                "handicapVisuel",
                "il n'y a pas d'audiodescription des œuvres : je ne peux pas profiter pleinement des collections sans accompagnement.",
                "low",
            ),
            (
                "handicapAuditif",
                "sur réservation, une visite avec interprète en langue des signes peut être organisée : le personnel est formé.",
                "none",
            ),
            (
                "temoignage",
                "le patrimoine est magnifique, mais l'accessibilité reste partielle selon les parcours.",
                "low",
            ),
            (
                "conseil",
                "appelez avant votre venue pour demander un parcours adapté ou une médiation renforcée.",
                "none",
            ),
        ],
    },
    {
        "placeId": "fst_tunis",
        "placeName": "Faculté des Sciences de Tunis",
        "posts": [
            (
                "handicapMoteur",
                "les amphithéâtres ne proposent pas de places pmr correctement aménagées en bas de salle.",
                "low",
            ),
            (
                "handicapMoteur",
                "le bâtiment principal n'a pas de rampe à l'entrée que j'ai utilisée : montée en fauteuil impossible seul.",
                "low",
            ),
            (
                "handicapVisuel",
                "sur le campus, aucun fil d'aide au guidage au sol : je dois compter sur quelqu'un pour me repérer.",
                "low",
            ),
            (
                "handicapAuditif",
                "les annulations de cours ne sont pas affichées sur un tableau visible partout : je rate l'info si personne ne m'écrit.",
                "low",
            ),
            (
                "temoignage",
                "naviguer entre les bâtiments en fauteuil est épuisant : pentes, seuils et chemins irréguliers.",
                "low",
            ),
            (
                "conseil",
                "rapprochez-vous du service social de l'université pour organiser votre accès aux cours et examens.",
                "none",
            ),
        ],
    },
    {
        "placeId": "clinique_dar_essalem",
        "placeName": "Clinique Dar Essalem",
        "posts": [
            (
                "handicapMoteur",
                "des rampes et un ascenseur desservent les niveaux : je peux me déplacer sans monter les escaliers.",
                "none",
            ),
            (
                "handicapMoteur",
                "le parking pmr est situé juste devant l'entrée principale, ce qui évite de longs trajets.",
                "none",
            ),
            (
                "handicapVisuel",
                "à l'accueil, une personne m'a accompagnée jusqu'au bon service au lieu de me laisser chercher seule.",
                "none",
            ),
            (
                "handicapAuditif",
                "dans la salle d'attente, des écrans affichent les files et les noms : je comprends l'ordre de passage sans entendre.",
                "none",
            ),
            (
                "temoignage",
                "parmi les structures que j'ai testées à Tunis, c'est l'une des plus réussies côté accessibilité pratique.",
                "none",
            ),
            (
                "conseil",
                "je la recommande aux personnes handicapées qui ont besoin de parcours clairs et d'équipements adaptés.",
                "none",
            ),
        ],
    },
]


def build_doc(
    place_id: str,
    place_name: str,
    post_type: str,
    body: str,
    danger: str,
) -> dict:
    b = body.strip()
    if b and b[0].islower():
        b = b[0].upper() + b[1:]
    contenu = f'"{place_name}" : {b}'
    return {
        "userId": FAKE_USER_ID,
        "contenu": contenu,
        "type": post_type,
        "images": [],
        "streamType": "post",
        "isLive": False,
        "liveStatus": "ended",
        "viewersCount": 0,
        "liveVideoUrl": None,
        "dangerLevel": danger,
        "validationYes": 0,
        "validationNo": 0,
        "createdAt": _rand_recent_dt(),
        "updatedAt": _rand_recent_dt(),
        "hasPlace": True,
        "placeText": place_name,
        "placeId": place_id,
        "placeName": place_name,
        "placeCategory": None,
        "placeConfidence": None,
        "riskLevel": "safe",
        "obstaclePresent": False,
        "aiSummary": None,
        "reasonCodes": [],
        "placeVerificationStatus": "none",
        "merciCount": 0,
        "merciUserIds": [],
        "obstacleVoterIds": [],
        "linkedLieuId": None,
        "postNature": None,
        "targetAudience": None,
        "inputMode": None,
        "isForAnotherPerson": None,
        "needsAudioGuidance": None,
        "needsVisualSupport": None,
        "needsPhysicalAssistance": None,
        "needsSimpleLanguage": None,
        "locationSharingMode": None,
        "isSeed": True,
    }


def main() -> None:
    client = MongoClient(MONGO_URI)
    coll = client[DB_NAME][COLLECTION]

    removed = coll.delete_many({"isSeed": True})
    inserted = 0

    for place in PLACES:
        pid = place["placeId"]
        pname = place["placeName"]
        for ptype, body, danger in place["posts"]:
            coll.insert_one(build_doc(pid, pname, ptype, body, danger))
            inserted += 1

    print(
        f"[seed_posts] Anciens posts seed supprimés : {removed.deleted_count} | "
        f"Nouveaux insérés : {inserted} | Base : {DB_NAME}.{COLLECTION}"
    )


if __name__ == "__main__":
    main()
