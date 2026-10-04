#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || { echo 'This bootstrap targets Linux x86_64 (WSL2 supported).'; exit 1; }
for command in docker curl python3 sha256sum; do command -v "$command" >/dev/null; done
docker info >/dev/null
docker compose version >/dev/null
mkdir -p .local/bin .local/docker jenkins/tools
export DOCKER_CONFIG="$PWD/.local/docker"
fetch_verified() {
  local url=$1 hash=$2 target=$3
  if [[ -f $target ]] && [[ $(sha256sum "$target" | cut -d' ' -f1) == "$hash" ]]; then return; fi
  curl --fail --location --show-error --silent --max-time 120 "$url" -o "$target.tmp"
  printf '%s  %s\n' "$hash" "$target.tmp" | sha256sum --check --status
  mv "$target.tmp" "$target"
  chmod 755 "$target"
}
fetch_verified https://github.com/kubernetes-sigs/kind/releases/download/v0.27.0/kind-linux-amd64 a6875aaea358acf0ac07786b1a6755d08fd640f4c79b7a2e46681cc13f49a04b .local/bin/kind
fetch_verified https://dl.k8s.io/release/v1.32.2/bin/linux/amd64/kubectl 4f6a959dcc5b702135f8354cc7109b542a2933c46b808b248a214c1f69f817ea .local/bin/kubectl
cp .local/bin/{kind,kubectl} jenkins/tools/
cp "$(command -v docker)" jenkins/tools/docker
export PATH="$PWD/.local/bin:$PATH" KUBECONFIG="$PWD/.local/kubeconfig"
# Create an IPv4-only bridge before Kind to support hosts without IPv6 iptables.
docker network inspect kind >/dev/null 2>&1 || docker network create kind >/dev/null
if kind get clusters | grep -qx portfolio; then
  docker start portfolio-control-plane >/dev/null
  if ! docker exec portfolio-control-plane test -e /dev/kmsg; then
    docker exec portfolio-control-plane mknod /dev/kmsg c 1 11
    docker exec portfolio-control-plane systemctl restart kubelet
  fi
  kind export kubeconfig --name portfolio --kubeconfig "$KUBECONFIG"
else
  kind create cluster --name portfolio --image kindest/node:v1.32.2@sha256:142f543559cc55d64e1ab9341df08e5ced84bd2e893736da8f51320f26f5950b --config k8s/kind.yaml --kubeconfig "$KUBECONFIG" --wait 120s > .local/kind-create.log 2>&1 &
  kind_pid=$!
  # Some nested containers omit the kernel log device; restore it inside our node only.
  while kill -0 "$kind_pid" 2>/dev/null; do
    if docker inspect portfolio-control-plane >/dev/null 2>&1; then
      if ! docker exec portfolio-control-plane test -e /dev/kmsg; then
        docker exec portfolio-control-plane mknod /dev/kmsg c 1 11
      fi
    fi
    sleep 2
  done
  if wait "$kind_pid"; then cat .local/kind-create.log; else cat .local/kind-create.log; exit 1; fi
fi
kubectl wait --for=condition=Ready node --all --timeout=120s
python3 - <<'PY'
import os, secrets, urllib.parse
from pathlib import Path
from xml.sax.saxutils import escape
p=Path('.env')
if not p.exists():
    gid=os.stat('/var/run/docker.sock').st_gid
    p.write_text('DOCKER_GID='+str(gid)+'\nJENKINS_ADMIN_PASSWORD='+secrets.token_hex(24)+'\n')
    p.chmod(0o600)
s=Path('.local/maven-settings.xml')
if not s.exists():
    u=urllib.parse.urlsplit(os.environ.get('HTTPS_PROXY',''))
    if u.username or u.password: raise SystemExit('Configure authenticated proxy in your local Maven settings; credentials are not copied automatically.')
    proxy=''
    if u.hostname:
        proxy='<proxies><proxy><id>local</id><active>true</active><protocol>http</protocol><host>'+escape(u.hostname)+'</host><port>'+str(u.port or 80)+'</port><nonProxyHosts>localhost|127.0.0.1</nonProxyHosts></proxy></proxies>'
    s.write_text('<settings>'+proxy+'</settings>')
    s.chmod(0o600)
PY
if [[ ! -f .local/java-cacerts ]]; then
  if [[ -f /etc/ssl/certs/java/cacerts ]]; then
    cp /etc/ssl/certs/java/cacerts .local/java-cacerts
  else
    docker create --name delivery-lab-truststore jenkins/jenkins:2.541.3-jdk21@sha256:c4098086090ca98491d4bf66182f5e3b015a8232f2acf2df209a212a5801aa8e >/dev/null
    docker cp delivery-lab-truststore:/opt/java/openjdk/lib/security/cacerts .local/java-cacerts
    docker rm delivery-lab-truststore >/dev/null
  fi
fi
# Public CA certificates and Kubernetes client config must be readable by Jenkins UID 1000.
chmod 644 .local/kubeconfig .local/java-cacerts .local/maven-settings.xml
build_fingerprint=$(find jenkins -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum | cut -d' ' -f1)
image_id=$(docker image inspect delivery-lab-jenkins:1.0.0 --format '{{.Id}}' 2>/dev/null || true)
if [[ -z $image_id ]] || [[ ! -f .local/jenkins-image-fingerprint ]] || [[ ! -f .local/jenkins-image-id ]] || [[ $build_fingerprint != "$(cat .local/jenkins-image-fingerprint)" ]] || [[ $image_id != "$(cat .local/jenkins-image-id)" ]]; then
  docker compose build jenkins
  printf '%s\n' "$build_fingerprint" > .local/jenkins-image-fingerprint
  docker image inspect delivery-lab-jenkins:1.0.0 --format '{{.Id}}' > .local/jenkins-image-id
fi
docker compose up -d --no-build
for attempt in $(seq 1 60); do
  if python3 scripts/check-jenkins.py >/dev/null 2>&1; then
    echo 'Jenkins login page is ready. User: hundrik. Password is in the ignored local .env file.'
    exit 0
  fi
  sleep 2
done
docker compose logs --tail=60 jenkins
exit 1
