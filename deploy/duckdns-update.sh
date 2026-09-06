#!/usr/bin/env bash
# Met a jour les deux entrees DuckDNS avec l IP publique courante de la bbox.
# A poser sur marquis (ou caddy-01) et a lancer toutes les 5 min par un timer.
# Le token vit dans /etc/duckdns.token (chmod 600), jamais dans le depot.
set -euo pipefail

TOKEN="$(cat /etc/duckdns.token)"
DOMAINS="hack-prod,hack-staging"

curl -fsS "https://www.duckdns.org/update?domains=${DOMAINS}&token=${TOKEN}&ip=" \
  | tee -a /var/log/duckdns.log
echo >> /var/log/duckdns.log
