#!/usr/bin/env bash
# Deploie une image deja construite par la CI, sur la VM de l environnement vise.
# On ne build JAMAIS sur marquis : la CI publie sur GHCR, ici on ne fait que tirer.
#
#   ./deploy/deploy.sh staging <sha>
#   ./deploy/deploy.sh prod    <sha>
set -euo pipefail

ENVIRONMENT="${1:?usage: deploy.sh <staging|prod> <sha>}"
SHA="${2:?usage: deploy.sh <staging|prod> <sha>}"

# ghcr.io refuse les majuscules, et le compte GitHub en a une.
: "${GITHUB_REPOSITORY:?}"
IMAGE="ghcr.io/${GITHUB_REPOSITORY,,}:${SHA}"
REMOTE_DIR=/opt/hack42

case "$ENVIRONMENT" in
  staging) APP_IP=192.168.1.131; APP_PORT=8080 ;;
  prod)    APP_IP=192.168.1.130; APP_PORT=8090 ;;
  *) echo "environnement inconnu: $ENVIRONMENT" >&2; exit 1 ;;
esac

echo "==> $ENVIRONMENT : $IMAGE"

# Le config.json vit uniquement sur la VM : changer de homeserver ne demande
# ni rebuild ni commit.
ssh -o StrictHostKeyChecking=accept-new "deploy@$APP_IP" bash -euo pipefail <<REMOTE
  cd "$REMOTE_DIR"

  # Trace de ce qui tourne, pour revenir en arriere a la main :
  #   export APP_IMAGE=\$(cat .image.previous) && docker compose up -d
  if [ -f .image ]; then cp .image .image.previous; fi
  echo "$IMAGE" > .image

  export APP_IMAGE="$IMAGE"
  export APP_PORT="$APP_PORT"
  docker compose pull
  docker compose up -d --remove-orphans
  docker image prune -f
REMOTE

# Smoke test SUR LA VM, pas sur l URL publique : Caddy y impose une basic auth,
# et on veut verifier l application, pas le reverse proxy.
for i in $(seq 1 20); do
  if curl -fsS --max-time 5 "http://$APP_IP:$APP_PORT/config.json" >/dev/null; then
    echo "==> $ENVIRONMENT en ligne (http://$APP_IP:$APP_PORT)"
    exit 0
  fi
  sleep 3
done

echo "==> $ENVIRONMENT ne repond pas sur http://$APP_IP:$APP_PORT/config.json" >&2
exit 1
