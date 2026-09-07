# Environnement hack42 — accès et infrastructure

Ce fichier est dans `deploy/` et non à la racine : le `README.md` du dépôt est
celui de Tchap, le remplacer créerait un conflit à chaque `git merge upstream`.

---

## 1. Se connecter

### Comptes existants

`greg`, `lnunez`, `gmarquis`, `cdutel` — mot de passe `Hack42Test!`.
Identifiant Matrix complet : `@greg:hack-tchap.duckdns.org`.

Une authentification HTTP (`hack42` / `w5jxsrrjaP`) protège les interfaces web.
Elle est demandée par le navigateur **avant** l'écran de connexion. Elle n'est
pas sur `matrix.` ni `auth.`, donc elle ne gêne pas les clients mobiles.

### Sur PC

| Adresse | Quoi |
|---|---|
| `https://hack-staging.duckdns.org` | notre fork, déployé automatiquement |
| `https://element.hack-tchap.duckdns.org` | client Tchap de référence, non modifié |
| `https://mail.hack-tchap.duckdns.org` | tous les mails envoyés par le serveur |

Vérifier en bas de l'écran de connexion que le serveur annoncé est
`hack-tchap.duckdns.org`. Si c'est `agent.tchap.gouv.fr`, le `config.json` de la
VM pointe encore sur le service réel de l'État — ne pas saisir d'identifiants.

### Sur téléphone

**Element X**, depuis le store. Serveur : `hack-tchap.duckdns.org`.

L'application **Tchap du store ne fonctionnera pas** : elle choisit son serveur
à partir de l'adresse email via l'annuaire de l'État, sans champ de serveur
personnalisé. Pour tester le client Tchap sur mobile, il faut le compiler depuis
`tchap-x-android` avec une configuration modifiée.

Element X exige l'authentification déléguée (MAS) et la découverte par
`.well-known`. Les deux sont en place, ainsi que de vrais certificats
Let's Encrypt — sans quoi aucun téléphone n'accepterait la connexion.

### Créer un compte

Deux voies.

**Self-service** : « Create Account » sur l'écran de connexion, puis récupérer
le lien de validation dans mailpit (`https://mail.hack-tchap.duckdns.org`). La
vérification d'email est obligatoire et tout le courrier atterrit là — donc un
inconnu qui s'inscrirait depuis Internet ne recevrait jamais rien et son compte
resterait inutilisable.

**En ligne de commande**, sur la VM 130 :

```bash
cd ~/tchap-dev
docker compose -f compose.yml -f compose-tchap-additional-services.yml -f compose.linux.yml \
  exec mas-tchap mas-cli -c /data/config.yaml manage register-user <login> \
  --yes --password '<motdepasse>' --email '<login>@hack-tchap.duckdns.org' \
  --display-name '<nom>' --ignore-password-complexity
```

Il n'y a **pas de captcha** sur l'inscription publique. Pour la fermer :
`password_registration_enabled: false` dans `tchap/mas/config.local.dev.yaml`.

---

## 2. Topologie

```
GitHub Actions (runners publics)   lint → build image → GHCR
         │
         ▼ push develop_tchap / tag v*
gh-runner-ubuntu  192.168.1.112    runner self-hosted, ssh vers les VM
         │
         ├──────────────────────────┬──────────────────────────
         ▼                          ▼
hack-prod-01  192.168.1.130   hack-staging-01  192.168.1.131
  stack Tchap complète            app du fork  :8080
  app prod du fork  :8090
         ▲                          ▲
         └────── caddy-01  192.168.1.105 ───────┘
                 TLS Let's Encrypt, box 80/443/7883
```

Hôte Proxmox : `marquis`, 192.168.1.200.

| Domaine | Vers |
|---|---|
| `hack-staging.duckdns.org` | 131:8080 — le fork |
| `hack-prod.duckdns.org` | 130:8090 — le fork, sur tag |
| `element` `matrix` `auth` `sso` `mail` `call` `livekit` `livekit-jwt` `.hack-tchap.duckdns.org` | 130, stack Tchap |

### Chaîne de livraison

| Événement | Effet |
|---|---|
| pull request | tests seulement, runners publics |
| push sur `develop_tchap` | build, publication GHCR, déploiement staging |
| tag `vX.Y.Z` | déploiement prod, après approbation |

L'image est construite par la CI et publiée sur GHCR ; les VM ne font que
`docker compose pull`. **On ne build jamais sur `marquis`** : le build d'Element
prend plusieurs minutes et immobiliserait la VM, et un retour arrière se résume
à changer de tag.

---

## 3. Ce qui tourne sur la VM 130

Stack `tchapgouv/tchap-docker-integration`, dans `~/tchap-dev` :
Synapse, MAS, Keycloak (mock ProConnect), serveur d'identité mocké, client
Tchap, PostgreSQL, Redis, mailpit, nginx, Element Call, LiveKit.

Trois fichiers nous appartiennent et ne viennent pas de l'amont :

- `compose.linux.yml` — nos correctifs (voir section 5)
- `tchap/synapse/Dockerfile` — Synapse plus les cinq modules Tchap
- `data-template/livekit/config.yaml` — port média modifié

Lancer la stack : `./start_tchap.sh` (il inclut `compose.linux.yml`).

### Les cinq modules Tchap

`room_access_rules`, `synapse_domain_rule_checker`, `synapse_patch_push_rules`,
`manage_last_admin`, `email_account_validity`.

Ce sont eux qui font qu'un Synapse se comporte comme Tchap : règles d'accès aux
salons, qui peut inviter qui, notifications par défaut, reprise du dernier
administrateur, expiration des comptes. Sans eux on a un Matrix ordinaire avec
l'habillage Tchap devant, ce qui ne permet pas de travailler sur les permissions.

Ils sont installés depuis les dépôts `tchapgouv`, **pas depuis PyPI** : les
paquets publiés sous ces noms sont les versions matrix-org d'origine.

Reconstruire après une montée de version de Synapse :

```bash
cd ~/tchap-dev && source .env
docker build --build-arg SYNAPSE_VERSION="$SYNAPSE_VERSION" \
  -t tchap-synapse:local -f tchap/synapse/Dockerfile tchap/synapse/
```

---

## 4. Décisions et leurs raisons

**Un homeserver à nous plutôt que le vrai Tchap.** Au départ le `config.json`
pointait sur `matrix.agent.tchap.gouv.fr`. Deux problèmes : on ne peut rien
tester (pas de comptes jetables, rien à casser), et surtout un client aux
couleurs de Tchap servi depuis un domaine quelconque et branché sur le service
réel est indiscernable d'un site de phishing. Le cas s'est produit : une
tentative de connexion a été envoyée au MAS de production de l'État.

**Authentification HTTP sur les deux clients web**, prod comprise, pour la même
raison. À retirer le jour où plus rien ne ressemble au service réel.

**Salons chiffrés par défaut** (`encryption_enabled_by_default_for_room_type:
all`), comme Tchap. C'est la contrainte que rencontrera tout bot devant lire une
conversation ou produire un compte-rendu. Passer à `off` dans
`tchap/synapse/homeserver.local.dev.light.yaml` pour itérer plus vite.

**`can_only_join_rooms_with_invite: false`**, contrairement à Tchap en
production : à `true` on ne peut plus rejoindre un salon public, ce qui rend les
tests pénibles.

**Deux VM séparées** pour prod et staging : on peut détruire et recréer le
staging sans toucher à la prod, avec snapshots indépendants.

**Média LiveKit en TCP et non en UDP.** Choix de la stack amont, documenté dans
son `compose.yml` : publier une plage de 10 000 ports crée autant de listeners.
Un seul port à rediriger au lieu d'une plage.

**Pare-feu Proxmox permissif au niveau datacenter.** Activer le sous-système est
nécessaire pour que les règles par VM s'appliquent, mais une politique DROP à ce
niveau couperait `marquis` et le reste du laboratoire. Le filtrage réel est dans
`/etc/pve/firewall/130.fw` et `131.fw`. SSH est ouvert à tout le LAN et non au
seul runner : la menace est Internet, pas le réseau local, et les adresses des
postes changent au gré du DHCP.

---

## 5. Problèmes rencontrés

### Perte de données silencieuse — le plus coûteux

Le `compose.yml` amont monte le dossier **parent** `/var/lib/postgresql`, alors
que l'image PostgreSQL déclare son volume sur `/var/lib/postgresql/data`. Docker
créait donc un volume **anonyme** pour les vraies données, que le
`docker compose down` en tête de `start_tchap.sh` orphelinait. Au démarrage
suivant : un volume neuf et vide.

Conséquence : **chaque redémarrage de la stack effaçait tous les comptes et tous
les salons**, sans le moindre message d'erreur. Découvert parce qu'une connexion
échouait sur `User not found`.

Corrigé par un volume nommé `pgdata` dans `compose.linux.yml`. Vérifié en
recréant les comptes puis en relançant `start_tchap.sh`.

### Caddyfile monté par inode

Docker monte un fichier unique par son inode. `sed -i` et `cp` ne modifient pas
en place, ils créent un nouveau fichier — le conteneur reste accroché à
l'ancien. Le conteneur voyait 117 lignes contre 148 sur l'hôte, et
`caddy validate` comme `caddy reload` répondaient « OK » sur un fichier invisible
pour lui. Un changement de port était perdu depuis une heure sans aucun signal.

**Après toute modification du Caddyfile :**

```bash
cd ~/caddy && docker compose up -d --force-recreate caddy
```

### CPU des machines virtuelles

Keycloak 26 refusait de démarrer : `Fatal glibc error: CPU does not support
x86-64-v2`. Le type de CPU par défaut de Proxmox, `kvm64`, n'expose pas ce jeu
d'instructions. Corrigé par `qm set 130 --cpu host` suivi d'un arrêt/démarrage
complet — un simple `reboot` ne suffit pas. Les autres VM du laboratoire ont le
même défaut latent.

### DuckDNS pointant ailleurs

`hack-tchap.duckdns.org` a été créé depuis un autre réseau et a enregistré cette
IP. Let's Encrypt validait donc ses challenges chez un inconnu :
`Timeout during connect (likely firewall problem)`. Vérifier la résolution avant
de chercher ailleurs. Un timer (§6) évite désormais le problème.

### Conflits de ports

MAS occupe le 8080 sur la VM 130 : l'app prod du fork y aurait échoué sur
`port already allocated`. Elle est passée sur **8090**.

Le port 7881 par défaut de LiveKit était déjà redirigé vers autre chose sur la
box. Le média du hackathon passe par le **7883**. Le test décisif consiste à
arrêter LiveKit et vérifier que le port cesse de répondre — sinon la redirection
pointe ailleurs.

### Chaîne CI/CD

- `github.repository` contient une majuscule, GHCR refuse : le nom d'image est
  calculé avec `${GITHUB_REPOSITORY,,}`.
- Les workflows CI et Deploy se déclenchaient **en parallèle** sur le même push,
  donc le déploiement partait avant que l'image n'existe. Fusionnés en un seul
  workflow avec `needs:`.
- Git sous Windows ne suit pas le bit exécutable : les scripts arrivaient en 644
  sur le runner (`Permission denied`, code 126). Corrigé par
  `git update-index --chmod=+x` et un `.gitattributes`.
- Le smoke test interrogeait l'URL publique, protégée par authentification HTTP,
  et recevait un 401. Il interroge maintenant la VM directement.
- Le pare-feu a d'abord bloqué ce même smoke test : le runner (192.168.1.112)
  doit être autorisé sur le port de l'app, pas seulement caddy-01.
- Le package GHCR est **privé par défaut**, même sur un dépôt public : à passer
  en public, sinon `docker compose pull` reçoit un 401.

### Stack écrite pour macOS

- `host.docker.internal` n'existe pas sous Linux. nginx redémarrait en boucle.
  Résolu par `extra_hosts: host.docker.internal:host-gateway`.
- Les fichiers TLS de certbot ont changé de chemin dans leur dépôt : le
  `setup.sh` récupérait des pages 404 de 14 octets.
- `lk-jwt-service` exige désormais `LIVEKIT_FULL_ACCESS_HOMESERVERS`, absent de
  l'entrypoint fourni.
- Le domaine `tchapgouv.com` est câblé en dur dans douze fichiers (mocks
  wiremock, realm Keycloak, configs). Changer de domaine impose de tous les
  substituer — et de repartir d'une base vide, le `server_name` de Synapse étant
  gravé dans les identifiants Matrix.

### Construction des modules Synapse

- `setuptools-scm` déduit le numéro de version des métadonnées git, absentes
  d'une archive tar.gz. D'où `SETUPTOOLS_SCM_PRETEND_VERSION`.
- `email_account_validity` n'embarque pas ses gabarits d'email dans la roue :
  Synapse refusait de démarrer sur un dossier `templates` introuvable. Ils sont
  copiés depuis l'archive du dépôt.

---

## 6. Automatismes

`duckdns.timer` sur `marquis`, toutes les 5 minutes : met à jour les trois
domaines. Token en `/etc/duckdns.token`.

`livekit-node-ip.timer` sur la VM 130, toutes les 10 minutes : LiveKit annonce
aux clients une adresse joignable, écrite en dur dans `LIVEKIT_NODE_IP`.
Contrairement au web, aucun DNS ne rattrape un changement d'IP ici — sans ce
script, la visio casse silencieusement. Le timer resynchronise la variable et
recrée le conteneur.

---

## 7. Opérations courantes

```bash
# état de la stack
cd ~/tchap-dev && docker compose -f compose.yml \
  -f compose-tchap-additional-services.yml -f compose.linux.yml ps

# logs d'un service
docker compose -f compose.yml -f compose-tchap-additional-services.yml \
  -f compose.linux.yml logs synapse --tail 50

# déployer en prod
git tag v0.1.0 && git push --tags

# revenir à l'image précédente sur une VM
cd /opt/hack42 && export APP_IMAGE=$(cat .image.previous) && docker compose up -d

# changer de homeserver sans reconstruire
# éditer /opt/hack42/config.json sur la VM, puis
docker compose up -d --force-recreate
```

Snapshots Proxmox, depuis `marquis` :

```bash
for id in 130 131; do qm snapshot $id avant-oleron; done
```
