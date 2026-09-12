# Objectif

Challenge LaSuite x 42 — Oléron, 14-18 septembre 2026.
Équipe : matorgue, michen, aykrifa, lnunez, gmarquis, cdutel.

On part de Tchap et on le pousse vers un modèle type Discord, avec une vraie
gestion de réunion. Ce qui compte, c'est que ça tourne le vendredi.

Huit chantiers. Pour chacun : ce qui existe déjà, ce qu'on construit, et le
piège à connaître.

---

## 1. L'affichage est brouillon

Tchap a déjà la bonne hiérarchie — espace, salon, fil — mais elle est illisible.
On ne distingue pas les niveaux, et les messages privés sont mélangés au reste.

**Ce qui existe.** Le modèle est natif dans Matrix : les Spaces sont les espaces,
les rooms les salons, les threads les fils. Rien à inventer côté serveur.

**Ce qu'on construit.** Uniquement du front : un panneau qui sépare nettement les
trois niveaux, et les conversations privées un-à-un ou petit groupe sorties
de l'arborescence, comme des MP.

**Le piège.** On devras utiliser leur DA donc pour ici pour les [components](https://suitenumerique.github.io/ui-kit/?path=/docs/components-button--docs), la [typographie](https://www.info.gouv.fr/marque-de-letat/la-typographie) et l'[UI kit](https://www.figma.com/community/file/1562860630562131728/lasuite-ui-kit) figma.

**La marche à suivre.**
1. Hiérarchie de l'espace : `GET /_matrix/client/v1/rooms/{espace}/hierarchy`. Le sync la donne déjà, l'appel ne sert qu'au premier rendu.
2. Reconnaître un MP : l'account data `m.direct` de l'utilisateur liste ses conversations un-à-un. C'est la seule source fiable, un salon à deux n'est pas forcément un MP.
3. Fils d'un salon : `GET /_matrix/client/v1/rooms/{salon}/threads`.
4. Rendre les trois niveaux avec les composants du UI kit. Rien à écrire côté serveur.

---

## 2. Aucune gestion de réunion

Aujourd'hui on lance une visio et c'est tout. Pas de planification, pas d'ordre
du jour, et tout se perd une fois la réunion finie.

**Ce qui existe.** Visio fait déjà caméra, partage d'écran, audio, chat,
transcription, diarisation et résumé par IA. Visio a même remplacé Element Call
dans Tchap. Tout ça est en production, on ne le refait pas.

**Ce qu'on construit.** Un bouton dans le salon et en privé qui ouvre une
réunion planifiée : date, heure, invitations, ordre du jour, documents joints.
Un salon temporaire dédié. Excalidraw et le partage de documents pendant la
réunion, via un widget. Après : le chat reste ouvert un temps défini, le
transcript et une synthèse arrivent, puis tout se clôt et devient téléchargeable
en archive.

**Le piège.** Visio n'expose pas l'état d'une réunion — en cours ou terminée.
C'est documenté comme bloquant dans le projet Hub de la DINUM. Notre clôture
automatique ne pourra donc pas s'appuyer dessus : on la pilotera par un minuteur
côté salon.

**La marche à suivre.**
1. Créer le salon temporaire : `POST /createRoom`, en passant `im.vector.room.access_rules` dans `initial_state` — sinon le module Tchap impose sa règle par défaut et chiffre tout.
2. Poser la réunion comme **événement d'état** maison : `PUT /rooms/{id}/state/fr.gouv.tchap.meeting/` avec date, ordre du jour, documents, statut. L'état est répliqué à tous les membres par le sync, sans base de données à nous.
3. Inviter : `POST /rooms/{id}/invite`.
4. Visio et Excalidraw : événement d'état `im.vector.modular.widgets`. C'est le mécanisme de widget qu'Element sait déjà afficher, on ne l'invente pas.
5. Clôturer : minuteur côté client, puisque Visio ne dit pas quand la réunion finit. À l'échéance, passer le statut à `termine` et verrouiller le salon en relevant `events_default` dans `m.room.power_levels`.
6. Archiver : paginer `GET /rooms/{id}/messages` et sérialiser le tout en un fichier.

---

## 3. Pas d'API pour créer salons et fils

On passe aujourd'hui par un compte « bot » bricolé à la main. Ça marche mal et
ça ne s'automatise pas.

**Ce qui existe.** L'API Matrix client-server sait déjà créer des salons et des
fils. Le problème n'est pas l'API, c'est la façon dont on s'y branche.

**Ce qu'on construit.** Un **Application Service** Matrix donc un service déclaré
côté Synapse, avec son jeton, qui agit sans compte utilisateur. C'est le
mécanisme prévu pour ça. Plus une petite API métier par-dessus, pour créer un
salon, inviter, et lancer les commandes utiles.

**Le piège.** Aucun.

**La marche à suivre.**
1. Écrire le registre YAML de l'AS : `id`, `as_token`, `hs_token`, `sender_localpart`, et les `namespaces` de comptes et de salons qu'il pilote.
2. Le déclarer dans `app_service_config_files` du `homeserver.yaml`, puis redémarrer Synapse.
3. L'AS appelle ensuite les endpoints Matrix habituels avec son `as_token`, et ajoute `?user_id=` pour agir au nom d'un compte de son namespace — sans mot de passe et sans connexion.
4. Poser par-dessus une petite API métier : créer un salon, inviter, lancer une commande. C'est elle que le front appelle, jamais Matrix directement.

---

## 4. Les droits sont figés

Création et suppression sont le même droit, donc impossible d'autoriser l'un
sans l'autre. Et un administrateur le reste à vie personne ne peut le démettre,
pas même celui qui a créé le salon.

**Ce qui existe.** Matrix gère les droits par niveaux de pouvoir (0 à 100) et par type
d'événement. Séparer création et suppression est donc possible dans le protocole.

**Ce qu'on construit.** Un module Synapse. Tchap en a déjà cinq dont
`manage_last_admin`, écrit pour un problème voisin. On en écrit un sixième, qui
sépare les droits et permet au créateur d'un salon de retirer le statut
administrateur.

**Le piège.** Synapse **interdit de rétrograder quelqu'un de niveau égal ou
supérieur**. Ce n'est pas un choix de Tchap, c'est le protocole. Ça se contourne
côté serveur, jamais côté client.

**La marche à suivre.**
1. Module Python branché sur le callback `check_event_allowed` des *third-party rules* — le même point d'entrée que les cinq modules Tchap existants.
2. Y intercepter les événements `m.room.power_levels`, et seulement eux.
3. Lire le créateur du salon dans `m.room.create`, le comparer à l'auteur de la modification.
4. Laisser passer la rétrogradation quand l'auteur est le créateur : c'est précisément le cas que Synapse refuse entre niveaux égaux.
5. Séparer création et suppression en donnant un niveau distinct par type d'événement dans le champ `events` des power levels.
6. Déclarer le module dans le bloc `modules:` du `homeserver.yaml`.

---

## 5. Les notifications sont confuses

On ne sait pas ce qui déclenche quoi, ni comment le régler.

**Ce qui existe.** Le module `synapse-patch-push-rules` de Tchap fixe déjà les
règles par défaut à l'inscription. La DINUM a la même issue ouverte sur Hub.

**Ce qu'on construit.** De la clarification d'interface voir qui, ou et quoi, symple efficace et claire.

**Le piège.** Aucun.

**La marche à suivre.**
1. Lire l'existant : `GET /_matrix/client/v3/pushrules/` rend toutes les règles, rangées par portée et par type.
2. Traduire chaque règle en une phrase lisible : ce qui la déclenche, dans quel salon, quel effet — c'est là qu'est tout le travail, pas dans l'API.
3. Modifier : `PUT /pushrules/global/{kind}/{id}/enabled` pour activer ou couper, `/actions` pour changer l'effet.
4. Ne pas réécrire les valeurs par défaut : `synapse-patch-push-rules` les pose déjà à l'inscription, les dupliquer côté client ferait diverger les deux.

---

## 6. On ne sait pas qui est qui, ni qui est là

Pas d'indicateur de disponibilité, et rien qui dise la fonction des gens.

**Ce qui existe.** Matrix gère la présence nativement, et l'indicateur de
disponibilité est sur la feuille de route Tchap pour ce semestre donc validé
comme utile, mais pas fait.

**Ce qu'on construit.** Un statut disponible / absent / occupé, et un encart de
fonction à côté du nom : « CTO DINUM », « RH MASA », « stagiaire MINARM ».

**Le piège.** Deux choses à vérifier. Synapse désactive souvent la présence par
défaut, pour des raisons de charge. Et pour la fonction, il faut une source :
la piste est `suitenumerique/people`, l'annuaire d'équipes de LaSuite — à ouvrir
pour voir si les fiches portent un intitulé de poste. Sinon, champ personnalisé
dans le profil Matrix.

**La marche à suivre.**
1. Présence : `PUT /_matrix/client/v3/presence/{userId}/status` pour publier, et le sync la rapporte pour les autres. Vérifié actif sur notre serveur, la crainte ci-dessus ne s'applique pas ici.
2. Fonction : l'annuaire `people` l'expose sur `GET /api/v1.0/contacts/`, avec poste, service et organisation. Il faut un jeton OAuth2, la route refuse l'anonyme.
3. Rapprocher les deux mondes par l'identifiant Matrix que porte la fiche (`customFields.matrix`).
4. Mettre en cache côté client : une requête par utilisateur croisé, jamais une par message affiché.

---

## 7. On ne retrouve rien

Il n'y a pas de recherche de messages. Une fois qu'une information a défilé,
elle est perdue : il faut se souvenir du salon et remonter à la main.

**Ce qui existe.** Matrix a une recherche côté serveur
(`POST /_matrix/client/v3/search`), active sur notre Synapse. Mais elle ne voit
que ce que le serveur peut lire, et on garde le chiffrement de bout en bout.
Vérifié sur notre serveur : un mot envoyé dans un salon public ressort dans des
centaines de résultats, le même mot envoyé en message privé chiffré en donne
**zéro** — alors que le destinataire, lui, le lit sans peine.

**Ce qu'on construit.** La recherche se fait donc entièrement dans le
navigateur, sur ce que l'utilisateur a déjà le droit de lire. Un index local
alimenté par le flux de synchronisation, rangé en IndexedDB, et une barre de
recherche façon Discord : filtrer par salon, par auteur, par date, et sauter
directement au message dans son fil.

**Le piège.** Trois. L'index appartient à un appareil : sur un nouveau
navigateur il est vide, il faut le reconstruire en repaginant l'historique. Il
contient du texte en clair sur le poste, ce qui doit être assumé et effacé à la
déconnexion. Et Element résout ça côté bureau avec Seshat, un composant natif
inutilisable dans un navigateur : on ne pourra pas le reprendre.

**La marche à suivre.**
1. Capter les messages **déjà déchiffrés** par le client à chaque synchronisation : corps, auteur, salon, horodatage, identifiant d'événement. Le déchiffrement est déjà fait, on ne refait rien.
2. Écrire dans IndexedDB avec un index inversé. Une bibliothèque de recherche en pur JavaScript suffit ; rien de natif, rien de serveur.
3. Reconstruire l'historique de façon **bornée** : `GET /rooms/{id}/messages?dir=b&limit=…`, N messages par salon et on s'arrête. Tout indexer au premier lancement ferait ramer le navigateur.
4. Chercher en local, puis sauter au message : `GET /_matrix/client/v3/rooms/{id}/context/{eventId}` rend les messages autour, de quoi ouvrir le fil au bon endroit.
5. Effacer l'index à la déconnexion — c'est du texte en clair.

---

## 8. Les documents vivent à côté des conversations

On colle un lien, il remonte dans le fil et disparaît. Rien ne dit qu'un salon,
un espace ou une réunion a des documents attachés.

**Ce qui existe.** La Suite Docs est en production : éditeur collaboratif temps
réel, avec une gestion fine des droits. Et le précédent est déjà là — **Meet
pousse les transcripts de réunion dans Docs et donne l'accès à qui le
demande**, par son API server-to-server. Côté Matrix, les événements d'état
portent déjà ce genre de métadonnée attachée à un salon ou à un espace.

**Ce qu'on construit.** Un panneau « Documents » sur le salon, l'espace et le
fil. Un événement d'état maison porte la liste des documents liés ; un fil
n'ayant pas d'état propre, on l'accroche à son message racine. Ça se branche
directement sur le chantier 2 : l'ordre du jour et le compte rendu d'une
réunion deviennent des documents liés au salon temporaire.

**Le piège.** Les droits ne suivent pas le lien. Docs a son propre contrôle
d'accès : coller l'adresse d'un document dans un salon ne l'ouvre à personne,
et les membres tomberont sur un refus. Il faut passer par l'API
server-to-server pour accorder l'accès au moment où on lie le document — c'est
exactement ce que fait Meet, donc le chemin est tracé.

**La marche à suivre.**
1. Lier : `PUT /rooms/{id}/state/fr.gouv.tchap.documents/` avec la liste (adresse, titre, qui l'a ajouté). Pour un fil, prendre l'identifiant de son message racine comme clé d'état, puisqu'un fil n'a pas d'état propre.
2. Afficher : l'état arrive par le sync, le panneau ne coûte aucun appel supplémentaire.
3. Ouvrir les droits, l'étape qu'on ne peut pas sauter : lire les membres par `GET /rooms/{id}/joined_members`, puis les passer à l'API server-to-server de Docs — comme Meet le fait pour ses transcripts.
4. Créer un document depuis Tchap : appeler l'API de Docs, récupérer l'adresse rendue, l'écrire dans l'état du salon.
5. À confirmer avant de s'engager : la référence exacte de cette API. On sait qu'elle existe et ce qu'elle permet, on ne l'a pas encore lue.

---

## Répartition

À décider entre nous. Deux repères :

Les chantiers 1, 2, 5, 6 et 7 sont côté client, dans `tchap-web-v4`. Le 2 est le plus gros, le 1 sert d'habillage à tout le reste. Le 7 est le plus autonome : il ne dépend d'aucun autre et ne touche pas au serveur.

Les chantiers 3 et 4 sont côté serveur application service et module
Synapse. Ils demandent du Python et une compréhension de Matrix, pas de front.

Le 8 est à cheval : le panneau et l'événement d'état côté client, l'appel à
l'API de Docs pour accorder les droits côté serveur.
