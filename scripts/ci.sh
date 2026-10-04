#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export KUBECONFIG=${KUBECONFIG:-$PWD/.local/kubeconfig}
export KIND_CLUSTER_NAME=${KIND_CLUSTER_NAME:-portfolio}
[[ $(kubectl config current-context) == "kind-$KIND_CLUSTER_NAME" ]] || { echo 'Expected the local Kind context'; exit 1; }
if [[ -z ${IMAGE_TAG:-} ]]; then
  revision=$(git rev-parse --short=12 HEAD 2>/dev/null || find src -type f -exec sha256sum {} + | sort | sha256sum | cut -c1-12)
  IMAGE_TAG="$revision-${BUILD_NUMBER:-local}"
fi
[[ $IMAGE_TAG =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}$ ]] || { echo 'Invalid image tag'; exit 1; }
image="delivery-lab:$IMAGE_TAG"
printf '\n[1/5] Maven verify: compile, tests, WAR\n'
mvn -B -ntp -Dmaven.repo.local="$PWD/.local/m2" clean verify
mkdir -p target/evidence target/runtime
(cd target/runtime && jar -xf ../ROOT.war)
printf '\n[2/5] Build non-root Tomcat image: %s\n' "$image"
docker build --network host -t "$image" .
printf '\n[3/5] Load image into local Kubernetes\n'
# Use containerd local import: Kind 0.27 / containerd 2 transfer import cannot unpack native snapshots.
docker save "$image" | docker exec -i "$KIND_CLUSTER_NAME-control-plane" ctr --namespace=k8s.io images import --local --snapshotter=native -
printf '\n[4/5] Deploy and wait for readiness\n'
kubectl apply -f k8s/namespace.yaml
sed "s|delivery-lab:bootstrap|$image|" k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml
kubectl -n delivery-lab rollout status deployment/delivery-lab --timeout=180s
kubectl -n delivery-lab get pods -o wide | tee target/evidence/pods.txt
kubectl -n delivery-lab get deployment delivery-lab -o jsonpath='{.spec.template.spec.containers[0].image}' > target/evidence/image.txt
printf '\n[5/5] Functional HTTP checks\n'
port=${SMOKE_PORT:-18080}
kubectl -n delivery-lab port-forward --address 127.0.0.1 service/delivery-lab "$port:8080" > target/evidence/port-forward.txt 2>&1 &
forward_pid=$!
trap 'kill "$forward_pid" 2>/dev/null || true; wait "$forward_pid" 2>/dev/null || true' EXIT
ready=false
for attempt in $(seq 1 30); do
  if curl -fsS --max-time 2 "http://127.0.0.1:$port/readyz" >/dev/null 2>&1; then ready=true; break; fi
  kill -0 "$forward_pid" 2>/dev/null || { cat target/evidence/port-forward.txt; exit 1; }
  sleep 1
done
[[ $ready == true ]] || { cat target/evidence/port-forward.txt; exit 1; }
bash scripts/smoke.sh "http://127.0.0.1:$port" | tee target/evidence/smoke.txt
printf '\nSUCCESS: %s\n' "$image"
