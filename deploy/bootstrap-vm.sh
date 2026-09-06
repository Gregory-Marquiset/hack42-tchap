#!/usr/bin/env bash
# A lancer en root SUR la nouvelle VM (hack-prod-01 ou hack-staging-01),
# juste apres le clone. Idempotent.
#
#   scp deploy/bootstrap-vm.sh root@192.168.1.130:/tmp/
#   ssh root@192.168.1.130 'bash /tmp/bootstrap-vm.sh <cle_publique_du_runner>'
set -euo pipefail

RUNNER_KEY="${1:?usage: bootstrap-vm.sh '<cle publique ssh du runner>'}"

echo "==> paquets"
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg qemu-guest-agent
systemctl enable --now qemu-guest-agent

echo "==> docker"
if ! command -v docker >/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg \
    -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
fi
systemctl enable --now docker

echo "==> utilisateur deploy"
id -u deploy >/dev/null 2>&1 || useradd -m -s /bin/bash deploy
usermod -aG docker deploy
install -d -m 0700 -o deploy -g deploy /home/deploy/.ssh
grep -qF "$RUNNER_KEY" /home/deploy/.ssh/authorized_keys 2>/dev/null \
  || echo "$RUNNER_KEY" >> /home/deploy/.ssh/authorized_keys
chown deploy:deploy /home/deploy/.ssh/authorized_keys
chmod 600 /home/deploy/.ssh/authorized_keys

echo "==> /opt/hack42"
install -d -o deploy -g deploy /opt/hack42

cat <<'MSG'

==> fait. Il reste, a la main :
    - copier deploy/compose.yml dans /opt/hack42/compose.yml
    - creer /opt/hack42/.env (chmod 600, proprietaire deploy)
    - docker login ghcr.io en tant que deploy, si le depot n est pas public
MSG
