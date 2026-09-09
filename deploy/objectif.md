# Objectif

Challenge LaSuite x 42 — Oléron, 14-18 septembre 2026.
Équipe : matorgue, michen, aykrifa, lnunez, gmarquis, cdutel.

On part de Tchap et on le pousse vers un modèle type Discord, avec une vraie
gestion de réunion. Ce qui compte, c'est que ça tourne le vendredi.

Six chantiers. Pour chacun : ce qui existe déjà, ce qu'on construit, et le
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

---

## 5. Les notifications sont confuses

On ne sait pas ce qui déclenche quoi, ni comment le régler.

**Ce qui existe.** Le module `synapse-patch-push-rules` de Tchap fixe déjà les
règles par défaut à l'inscription. La DINUM a la même issue ouverte sur Hub.

**Ce qu'on construit.** De la clarification d'interface voir qui, ou et quoi, symple efficace et claire.

**Le piège.** Aucun.

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

---

## Répartition

À décider entre nous. Deux repères :

Les chantiers 1, 2, 5 et 6 sont côté client, dans `tchap-web-v4`. Le 2 est le plus gros, le 1 sert d'habillage à tout le reste.

Les chantiers 3 et 4 sont côté serveur application service et module
Synapse. Ils demandent du Python et une compréhension de Matrix, pas de front.
