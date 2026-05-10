# Module Transport Adapté Intelligent — État d'avancement

Ce document compare le **cahier des charges (4.4)** du module Transport Adapté Intelligent avec l’existant dans le backend Ma3ak (NestJS + Flask).

---

## Déjà fait

### A. Demande et planification du transport

| Exigence | Implémentation |
|----------|----------------|
| Demande immédiate ou planifiée (date/heure) | **Fait.** `CreateTransportDto` + schéma : `dateHeure` (ISO), `depart`, `destination`, coordonnées départ/arrivée. |
| Lieu de départ et destination | **Fait.** Champs `depart`, `destination`, `latitudeDepart`, `longitudeDepart`, `latitudeArrivee`, `longitudeArrivee`. |
| Choix type : urgence ou quotidien | **Fait.** Enum `TransportType` : `URGENCE`, `QUOTIDIEN` dans la demande. |
| Évaluation du chauffeur après le trajet | **Fait.** Module `transport-review` : `POST /transport-reviews/transport/:transportId` avec `note` (1–5) et `commentaire`. Recalcul de la `noteMoyenne` de l’accompagnant. |
| Liste des accompagnants disponibles | **Fait.** `GET /transport/matching?latitude=...&longitude=...` retourne les accompagnants disponibles (rôle ACCOMPAGNANT, `disponible: true`, `statut: ACTIF`). |
| Acceptation / annulation d’une demande | **Fait.** `POST /transport/:id/accept`, `POST /transport/:id/cancel`. Statuts : `EN_ATTENTE`, `ACCEPTEE`, `ANNULEE`. |
| Mes demandes (demandeur + accompagnant) | **Fait.** `GET /transport/me` → `asDemandeur`, `asAccompagnant`. `GET /transport/available` pour les demandes en attente. |

### B. Matching (partiel)

| Exigence | Implémentation |
|----------|----------------|
| Données pour un score (expérience, notes, spécialisation, proximité) | **Fait.** Si `FLASK_TRANSPORT_URL` est défini, NestJS appelle Flask `POST /api/match` ; réponse avec `distance_km`, `score_matching`. Sinon tri par `noteMoyenne`. |

### C. Fondations techniques

| Exigence | Implémentation |
|----------|----------------|
| Véhicules avec accessibilité | **Fait.** Schéma `Vehicle` avec `accessibilite` (rampeAcces, siegePivotant, coffreVaste, climatisation, animalAccepte). |
| Position utilisateur (chauffeur / accompagnant) | **Fait.** User : `latitude`, `longitude`, `lastLocationAt` ; `PATCH /user/me/location` pour mise à jour. |
| Géocodage et itinéraire | **Fait.** Module `map` : géocodage, géocodage inverse, calcul d’itinéraire (OSRM) avec distance (m) et durée (s). |
| ETA (estimation temps d’arrivée) | **Fait.** `GET /transport/:id/eta` pour un transport accepté (Flask ou calcul Haversine de secours). |
| Détection urgence par mots-clés | **Fait côté Flask.** `POST /api/demande` avec `description` → `urgence`, `mots_detectes`. Non utilisé par NestJS. |

---

## Pas encore fait (tâches restantes)

### A. Demande et planification

| # | Tâche | Détail |
|---|--------|--------|
| A1 | **Type d’assistance requise** | Champ dans la demande (ex. aide à l’embarquement, fauteuil roulant, etc.). À ajouter dans `CreateTransportDto` et schéma `TransportRequest` (ex. `typeAssistance` ou `besoinsAssistance[]`). |
| A2 | **Marquer un transport comme terminé** | Endpoint du type `POST /transport/:id/termine` (ou `PATCH /transport/:id` avec `statut: TERMINEE`) pour passer une demande de `ACCEPTEE` à `TERMINEE`. Actuellement le statut `TERMINEE` est seulement vérifié dans transport-review, jamais défini par un endpoint. |
| A3 | **Enregistrer la durée du trajet** | Lors du passage à `TERMINEE`, enregistrer une durée (ex. `dureeMinutes` ou `dateHeureArrivee`) dans le schéma pour l’historique. |

### B. Matching intelligent (cœur du module)

| # | Tâche | Détail |
|---|--------|--------|
| B1 | **Intégration NestJS ↔ Flask** | Faire appeler par NestJS l’API Flask `POST /api/match` (avec position utilisateur, liste des accompagnants + leurs positions/spécialisation/notes/expérience, type handicap, urgence) et utiliser la réponse triée par score au lieu du simple tri par `noteMoyenne`. |
| B2 | **Proximité dans le matching NestJS** | Au minimum : utiliser `latitude`/`longitude` des accompagnants et du demandeur dans le matching (soit via Flask, soit calcul Haversine côté NestJS). Actuellement `findMatchingChauffeurs` reçoet lat/lon mais ne les utilise pas ; `findAccompagnantsDisponibles` n’utilise pas la position. |
| B3 | **Matching handicap ↔ chauffeur ↔ véhicule** | Associer explicitement : type de handicap du demandeur, spécialisation de l’accompagnant, et véhicule adapté (rampe, etc.). Implique de lier une demande à un **véhicule** (ex. `vehicleId` dans `TransportRequest`) et de filtrer/pondérer par compatibilité handicap / véhicule. |
| B4 | **Score de compatibilité exposé** | Retourner le score (et si possible ses composantes) dans la réponse du matching pour l’afficher dans l’app (expérience, évaluations, spécialisation, proximité). |

### C. Types de transport et priorisation

| # | Tâche | Détail |
|---|--------|--------|
| C1 | **Priorisation des urgences** | Traiter en priorité les demandes `typeTransport: URGENCE` : tri des demandes en attente (urgences en premier), et/ou bonus urgence dans le matching (déjà prévu côté Flask, à exploiter via B1). |
| C2 | **Priorisation / marquage “médical”** | Optionnel : champ ou type “trajet médical” (ex. rendez-vous hôpital) pour priorisation ou statistiques. Peut être un champ `motif` ou `categorie` (MEDICAL, ADMINISTRATIF, QUOTIDIEN, etc.). |

### D. Situations critiques (mode urgence)

| # | Tâche | Détail |
|---|--------|--------|
| D1 | **Alerte immédiate des chauffeurs proches** | Pour les demandes URGENCE : s’appuyer sur le matching par proximité (B1/B2) et, si besoin, notifications ciblées (module `notification`) vers les accompagnants les plus proches. |
| D2 | **Localisation en temps réel** | Déjà possible côté données (position utilisateur). À compléter : utilisation de cette position pour ETA et suivi (voir E1, E2). |
| D3 | **Détection urgence dans la description** | Utiliser côté NestJS le résultat de Flask `POST /api/demande` (ou reproduire la logique) pour pré-remplir ou confirmer `typeTransport: URGENCE` à partir de la description texte de la demande (optionnel). |

### E. Suivi et transparence du trajet

| # | Tâche | Détail |
|---|--------|--------|
| E1 | **ETA pour un trajet en cours** | Endpoint ou logique métier du type : pour une demande `ACCEPTEE`, calculer l’ETA (chauffeur → point de prise en charge) en s’appuyant sur la position de l’accompagnant (`user.latitude/longitude`) et les coordonnées du trajet. Soit appel à Flask `GET /api/eta`, soit calcul côté NestJS, puis exposition dans `GET /transport/:id` ou `GET /transport/:id/eta`. |
| E2 | **Suivi position / itinéraire pour un trajet** | Exposer pour une demande donnée : position actuelle de l’accompagnant (et/ou du demandeur), itinéraire prévu (déjà possible via `map/route` avec départ/arrivée). Par ex. `GET /transport/:id/suivi` retournant position + ETA + géométrie de l’itinéraire. |
| E3 | **Partage du trajet avec un proche** | Fonctionnalité “partager mon trajet” : lien temporaire, token, ou envoi d’un lien de suivi à un contact (emergency contact ou numéro). Non implémenté (pas d’endpoint ni de schéma dédié). |
| E4 | **Historique avec durée du trajet** | `GET /transport/me` retourne déjà la liste des trajets. À compléter : pour chaque trajet terminé, inclure la **durée du trajet** (et si possible heure d’arrivée), ce qui suppose A2 et A3. |

---

## Synthèse

- **Fait :** Demande (départ, destination, date/heure, type urgence/quotidien), acceptation/annulation, évaluation chauffeur (note + commentaire), liste des demandes, véhicules avec accessibilité, position utilisateur, géocodage/itinéraire, ETA et détection urgence côté Flask (non branchés au flux NestJS).
- **À faire en priorité :**  
  - Intégration du **matching intelligent** (NestJS ↔ Flask ou équivalent avec proximité + spécialisation + urgence).  
  - **Marquer un transport comme terminé** et enregistrer la **durée**.  
  - **Type d’assistance** dans la demande.  
  - **ETA et suivi** par trajet (position + ETA pour une demande donnée).  
- **Ensuite :** Lien véhicule ↔ transport, priorisation urgences/médical, partage du trajet avec un proche.

---

*Document mis à jour après implémentation des tâches du module Transport Adapté. Config : FLASK_TRANSPORT_URL dans .env (voir .env.example).*
