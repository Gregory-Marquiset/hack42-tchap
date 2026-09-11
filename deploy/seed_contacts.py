"""Cree une fiche de contact pour chaque utilisateur de la demo.

`make demo` ne genere que comptes, equipes, domaines et boites mail : les fiches
de contact ne sont jamais peuplees. Ce script leur donne un poste plausible pour
que l annuaire ait l air vivant quand on le branche sur Tchap.

Le champ customFields porte l identifiant Matrix, deduit de l email : c est lui
qui permettra de faire la jointure annuaire <-> Tchap cote client.

Idempotent : un utilisateur qui a deja une fiche est ignore.

    docker compose exec -T app-dev python manage.py shell < seed_contacts.py
"""

import random

from core.models import Contact, User

random.seed(42)  # reproductible : deux executions donnent les memes postes

ORGS = [
    ("DINUM", ["Pole logiciels", "Pole infrastructures", "Mission societe numerique"]),
    ("MASA", ["Sous-direction des systemes d information", "Bureau des ressources humaines"]),
    ("MINARM", ["Direction generale du numerique", "Etat-major"]),
    ("ANCT", ["Programme France Numerique", "Pole territoires"]),
    ("ANSSI", ["Sous-direction operations", "Centre de cyberdefense"]),
    ("DGFIP", ["Service des systemes d information", "Bureau du budget"]),
]

# Poids grossiers : peu de dirigeants, beaucoup de contributeurs.
TITLES = [
    ("CTO", 1), ("DSI", 1), ("RSSI", 2),
    ("Chef de projet", 8), ("Cheffe de projet", 8),
    ("Developpeur", 12), ("Developpeuse", 12),
    ("Administrateur systeme", 6), ("Administratrice systeme", 6),
    ("Product owner", 5), ("Designer UX", 4),
    ("Charge de mission", 10), ("Chargee de mission", 10),
    ("Juriste", 3), ("Analyste donnees", 5),
    ("Stagiaire", 8), ("Apprenti", 4), ("Apprentie", 4),
]
POOL = [t for t, weight in TITLES for _ in range(weight)]

PRENOMS = [
    "Camille", "Lucas", "Ines", "Hugo", "Sarah", "Nathan", "Lea", "Maxime",
    "Chloe", "Theo", "Manon", "Antoine", "Julie", "Mehdi", "Alice", "Yanis",
    "Clara", "Paul", "Nour", "Adrien", "Sofia", "Victor", "Emma", "Karim",
]
NOMS = [
    "Martin", "Bernard", "Dubois", "Thomas", "Robert", "Richard", "Petit",
    "Durand", "Leroy", "Moreau", "Simon", "Laurent", "Lefebvre", "Michel",
    "Garcia", "David", "Bertrand", "Roux", "Vincent", "Fournier",
]

HOMESERVER = "hack-tchap.duckdns.org"

deja = set(Contact.objects.filter(user__isnull=False).values_list("user_id", flat=True))
crees = ignores = erreurs = 0

for user in User.objects.all().iterator():
    if user.id in deja:
        ignores += 1
        continue

    org, departements = random.choice(ORGS)
    localpart = (user.email or "").split("@")[0] or str(user.id)[:8]

    data = {
        "organizations": [
            {
                "name": org,
                "department": random.choice(departements),
                "jobTitle": random.choice(POOL),
            }
        ],
        "customFields": {"matrix": f"@{localpart}:{HOMESERVER}"},
    }
    if user.email:
        data["emails"] = [{"type": "Work", "value": user.email}]

    nom_complet = user.name or f"{random.choice(PRENOMS)} {random.choice(NOMS)}"

    try:
        Contact.objects.create(
            user=user, owner=user, full_name=nom_complet[:150], data=data
        )
        crees += 1
    except Exception as exc:  # noqa: BLE001 - on veut continuer malgre un cas isole
        erreurs += 1
        if erreurs <= 3:
            print(f"  echec pour {user.email}: {exc}")

print(f"crees: {crees} | ignores: {ignores} | erreurs: {erreurs}")
print(f"total fiches en base: {Contact.objects.count()}")
