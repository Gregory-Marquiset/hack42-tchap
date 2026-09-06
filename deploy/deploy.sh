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
  staging)
    APP_HOST="deploy@192.168.1.131"
    URL="https://hack-staging.duckdns.org/config.json"
    ;;
  prod)
    APP_HOST="deploy@192.168.1.130"
    URL="https://hack-prod.duckdns.org/config.json"
    ;;
  *) echo "environnement inconnu: $ENVIRONMENT" >&2; exit 1 ;;
esac

echo "==> $ENVIRONMENT : $IMAGE"

# Le .env vit uniquement sur la VM, jamais dans le depot ni dans la CI.
ssh -o StrictHostKeyChecking=accept-new "$APP_HOST" bash -euo pipefail <<REMOTE
  cd "$REMOTE_DIR"

  # Trace de ce qui tourne, pour pouvoir revenir en arriere a la main :
  #   export APP_IMAGE=\$(cat .image.previous) && docker compose up -d
  if [ -f .image ]; then cp .image .image.previous; fi
  echo "$IMAGE" > .image

  export APP_IMAGE="$IMAGE"
  docker compose pull
  docker compose up -d --remove-orphans
  docker image prune -f
REMOTE

# Smoke test : si /healthz ne repond pas, le job echoue et tu le vois tout de
# suite, pas au moment de la demo.
for i in $(seq 1 20); do
  if curl -fsS --max-time 5 "$URL" >/dev/null; then
    echo "==> $ENVIRONMENT en ligne ($URL)"
    exit 0
  fi
  sleep 3
done

echo "==> $ENVIRONMENT ne repond pas sur $URL" >&2
exit 1
