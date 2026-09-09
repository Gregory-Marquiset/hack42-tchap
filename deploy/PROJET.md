# mmalgc hackathon vs Le hub

Écrit le 9 septembre 2026, cinq jours avant le challenge (Oléron, 14-18 septembre).
Équipe : matorgue, michen, aykrifa, lnunez, gmarquis, cdutel.

---

[1. L'officiel — ce que fait la DINUM](#1-lofficiel--ce-que-fait-la-dinum)

[2. Le hub](#2-le-hub)

[3. Notre projet](#3-notre-projet)

---

## 1. L'officiel — ce que fait la DINUM

### Où trouver l'information fiable

Il existe une **feuille de route consolidée de toute LaSuite**, publique, avec
les statuts par semestre pour les neuf produits : ProConnect, Tchap, France
Transfert, Docs, Visio, Fichiers, Grist, Assistant IA, Messagerie.

| Document | Lien | Mise à jour |
|---|---|---|
| Sommaire des roadmaps | `docs.numerique.gouv.fr/docs/bdd8a2b9-66a8-4655-8f47-a791fc55454a/` | 8 jours |
| **Roadmap globale LaSuite** | `.../docs/13ad8680-8a14-4819-9e54-1f1bb2268892/` | 1 jour |
| Roadmap Fichiers | `.../docs/389a879e-5929-4e72-bbf9-9e9fe9e234a5/` | 1 jour |
| Roadmap Visio | `.../docs/b0590eb9-6729-40d5-9ccf-97bc2fce1654/` | 1 mois |
| Roadmap Docs | `.../docs/406b1ea6-17fb-489b-b06c-b8e95c755306/` | 1 mois |
| Roadmap Tchap | `.../docs/5b9a56f0-22cf-44e0-81fd-c9f6bec2de2d/` | 3 mois |

**La roadmap globale est la seule à jour et la seule avec des statuts.** Les
roadmaps produit sont plus anciennes et souvent sans avancement — celle de Tchap
date de trois mois et alimente la page publique `tchap.numerique.gouv.fr`, qui
donne donc une image fausse de ce qui reste à faire.

Les documents portent tous l'avertissement : *« la feuille de route n'est pas un
document contractuel et est sujette à des changements fréquents »*.

### Ce qui est livré ✅

Ce qu'on croyait à construire, et qui est déjà en production :

| Produit | Fonctionnalité | Quand |
|---|---|---|
| Tchap | appels audio et vidéo de groupe **directement dans les salons** | S1 2025 |
| Visio | **remplacement d'Element Call par Visio dans Tchap** | S1 2026 |
| Visio | transcription asynchrone (diarisation + synthèse) | S1 2025 |
| Visio | **résumés automatiques par workflow d'IA agentique** | S2 2025 |
| Visio | transcription et sous-titrage temps réel | S2 2025 |
| Visio | SIP audio, modération, plugin Outlook, fond virtuel | 2025-2026 |
| Messagerie | interop Visio : créer et rejoindre une room | S2 2025 |
| Tchap | apps mobiles modernisées, client lourd, recherche chiffrée | 2025-2026 |
| Fichiers | partage, création de documents, export, tri, quotas, droits hérités | 2026 |

**Conséquence directe pour nous.** L'interconnexion Tchap–Visio et l'assistant de
réunion — le cœur de notre proposition initiale — **sont déjà construits**. La
documentation utilisateur de Visio le confirme : la transcription part dans un
document Docs dont le lien est envoyé par email à la fin de la réunion.

Ce qui manque n'est pas la brique, c'est **son raccordement au fil de
discussion** : personne ne pousse ce lien dans le salon où la réunion a eu lieu.
C'est exactement ce que décrivent les « future needs » de l'issue #38 de Hub.

### Ce qui est en cours 🔄

| Produit | Fonctionnalité |
|---|---|
| Tchap | interopérabilité via le protocole Matrix |
| Visio | chiffrement de bout en bout, SIP vidéo |
| Fichiers | **enregistrements Visio dans Fichiers**, **Docs dans Fichiers** |
| Fichiers | liens de partage éphémères, historique et versions |
| Docs | recherche hybride, barre d'outils IA, suggestions |
| ProConnect | migration de l'infrastructure cloud |

### Ce qui est attendu — S2 2026

| Produit | Fonctionnalité |
|---|---|
| **Tchap** | **interopérabilité avec les autres outils de la Suite** |
| Tchap | indicateur de disponibilité, fédération Matrix, CSPN, PRA |
| **Visio** | **amélioration du chat (envoi de fichiers)**, breakout rooms |
| Visio | lister et configurer ses liens depuis l'accueil, test micro/caméra |
| **Fichiers** | **partager ses fichiers depuis les autres produits de LaSuite** |
| Fichiers | Grist dans Fichiers, pièces jointes Messagerie, accès Assistant IA |
| Docs | **gestion de droits d'accès par groupe**, import Word, accessibilité |

La roadmap Fichiers a une section entière intitulée **« Faire Suite — Fichiers
comme pivot inter-produit »**. C'est la même intention que Hub, vue depuis le
stockage.

### Deux choses à savoir

**Hub n'apparaît dans aucune de ces feuilles de route.** Le produit est plus
récent que les documents. Son jalon v1 sur GitHub en tient lieu (voir §2).

**La signature électronique n'est nulle part.** L'idée bonus du challenge —
« intégrer la signature électronique et l'horodatage sur un fichier Drive » —
n'apparaît que dans les « Perspectives » de Fichiers, c'est-à-dire non planifié.
Si quelqu'un cherche un sujet sans concurrence, il est là.

---

## 2. Le hub

### Ce que c'est

Aujourd'hui un agent public jongle entre trois outils : **Tchap** pour discuter,
**Visio** pour se voir, **Fichiers** pour les documents.

La DINUM construit **Hub** (`github.com/suitenumerique/hub`) pour n'en faire
qu'un. Leur description tient en une ligne :

> group chat + meet + drive = hub

Concrètement : une conversation où on lance un appel vidéo sans changer
d'application, où on partage un fichier sans coller un lien, où la réunion
laisse une trace dans le fil.

**Pourquoi cette section.** Hub n'est pas notre projet — on travaille sur Tchap,
voir `objectif.md`. Mais c'est la réponse officielle de la DINUM au même
problème, et il faut la connaître pour deux raisons : ne pas refaire ce qu'ils
font, et savoir où nos chantiers recoupent les leurs quand on présentera.

### Où il en est

Créé le 5 mai 2026. Trois développeurs actifs, des commits tous les jours, et un
README qui annonce franchement « pas prêt pour la production ».

**Le chat marche, et rien d'autre** — mais il est complet : messages, fils de
discussion, réactions, accusés de lecture, non-lus, invitations, favoris,
recherche de personnes, brouillons, gestion d'erreurs.

Deux entrées de leur journal disent où ils en sont :

> « Show Documents as unavailable until Matrix media support lands »
> « Remove the meeting entry from the side panel quick actions »

Ils ont **retiré** les boutons Documents et Réunion parce qu'ils ne
fonctionnaient pas. Le produit avance par le chat, le reste est assumé comme
différé.

### La technique

Front **Next.js**, back **Django REST** volontairement mince, Postgres et Redis.
**Keycloak** pour l'identité en développement, ProConnect en production.
**MinIO** pour les fichiers. **Matrix** (Synapse + MAS) comme moteur de
messagerie.

Point important : le front parle à Matrix **directement depuis le navigateur**,
via `matrix-js-sdk`. Le backend Django ne voit pas passer les messages, d'où
l'absence de modèle de données pour les conversations côté serveur.

Ils ont une abstraction `Driver` (`MatrixDriver`) : l'interface ne connaît pas
Matrix. Une contribution côté interface n'a donc pas à comprendre Matrix en
profondeur.

Le dépôt a été démarré depuis le projet **Docs** de LaSuite — même pile, mêmes
conventions. C'est pour ça que tous les projets se ressemblent.

### Leur feuille de route : le jalon v1

> **Hub v1 · matrix client + groups + Drive & Meet interops**
> 18 issues, aucune échéance annoncée

Le titre nomme les trois piliers : le client Matrix, **les groupes**, et
l'interop avec Drive et Meet.

Ce qui nous concerne : leur notion de « groupe » est une entité nommée avec des
paramètres, des membres et des invitations — mais qui ne contient **qu'une seule
conversation**. Ils n'ont pas de hiérarchie. Notre chantier 1, l'arborescence
espace → salon → fil, va donc plus loin que leur v1.

Et leur issue #38, le bouton réunion, est **bloquée** parce que Visio n'expose
pas l'état d'une réunion. C'est le même mur que notre chantier 2 : à contourner
par un minuteur.

### Les 21 issues ouvertes

| Chantier | Issues | État |
|---|---|---|
| **Groupes** — créer, paramétrer, membres | #30 #31 #32 #33 #34 | **libres**, rien n'existe dans le code |
| **Fichiers et Drive** | #28 #35 #36 #37 | **libres** |
| Connexion et déchiffrement | #29 | libre |
| Gestion globale des erreurs | #47 | libre, hors v1 |
| Finitions Tchap | #45 | libre, hors v1 |
| Tests backend instables | #51 | libre, hors v1 |
| Réunion — lancer/rejoindre depuis le chat | #38 | pris, **et bloqué** : Visio n'expose pas l'état d'une réunion |
| Notifications, recherche, non-lus, fils, traductions | #49 #42 #43 #25 #22 #26 | pris |

Toutes portent le label « Design approved » et renvoient à des maquettes Figma
et à des specs écrites.

### Un chantier de fond en cours

Une pull request ouverte veut **remplacer `matrix-js-sdk` par le SDK Rust**.
C'est une refonte de la couche de communication. Avant de commencer quoi que ce
soit côté front, demander où ça en est — c'est le genre de changement qui rend
un travail de quatre jours incompatible en une nuit.

### Leurs conventions

Messages de commit : `<gitmoji>(scope) titre`, description obligatoire après une
ligne vide. Exemple réel : `✨(frontend) add matrix client and oidc auth`.

Commits **signés deux fois** : `--signoff` pour le DCO et `-S` pour la signature
cryptographique. Sans ça, la PR est rejetée.

Avant toute PR : `make test`, `make lint`, `make frontend-lint`. Les PR attendent
captures ou vidéo à l'appui.

---

## 3. Notre projet

**Les six chantiers sont dans `objectif.md`.** Cette section dit où on en est et
ce qu'il reste à préparer.

On travaille sur **Tchap** — le client `tchap-web-v4` et des modules Synapse —
pas sur Hub. L'objectif est une démonstration qui tourne le vendredi.

### Où on en est

**L'environnement de travail est complet et éprouvé.**

- Fork de Tchap (`hack42-tchap`) avec CI/CD : push → build → image GHCR →
  déploiement staging ; tag `v*` → prod
- Deux VM Proxmox filtrées, avec snapshots
- Un homeserver Tchap complet : Synapse avec ses cinq modules, MAS, Keycloak,
  serveur d'identité mocké, mailpit, Element Call et LiveKit
- Accès validés : navigateur, mobile (Element X), visio
- Comptes pour les six devs, plus `demo1` à `demo5` pour les testeurs
- Mise à jour DNS automatique, pare-feu, documentation (voir `README.md`)

C'est notre principal avantage : les cinq modules Tchap sont déjà installés sur
notre Synapse, donc **le chantier 4 a son terrain prêt**. Peu d'équipes auront ça.

Hub tourne aussi en local sur la VM 131, avec sa stack Matrix et des
conversations de test — utile pour comparer, pas pour livrer.

### Ce qu'il reste à préparer

- [ ] **Se répartir les six chantiers** — voir les repères en fin d'`objectif.md`
- [ ] Récupérer l'UI kit LaSuite sur Figma (fichier communautaire, accès libre)
      et la typographie Marianne, pour le chantier 1
- [ ] Vérifier si la présence Matrix est activée sur notre Synapse — chantier 6
- [ ] Ouvrir `suitenumerique/people` pour voir si les fiches portent un intitulé
      de poste — chantier 6
- [ ] Déclarer un Application Service de test sur notre Synapse — chantier 3
- [ ] Regarder comment `manage_last_admin` est écrit : c'est le modèle du module
      qu'on doit produire — chantier 4
- [ ] Trouver un widget Excalidraw compatible Matrix — chantier 2
- [ ] Chacun : Docker fonctionnel, et un CPU virtuel compatible si VM
      (Keycloak 26 exige x86-64-v2)
- [ ] Refaire un snapshot de la VM 130 — le dernier précède les modules Synapse
      et Element Call
