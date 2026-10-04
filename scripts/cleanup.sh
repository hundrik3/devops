#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DOCKER_CONFIG="$PWD/.local/docker" KUBECONFIG="$PWD/.local/kubeconfig"
docker compose down
if [[ -x .local/bin/kind ]]; then
  .local/bin/kind delete cluster --name portfolio
fi
echo 'Lab services and the portfolio cluster stopped. Jenkins history remains in its named volume.'
echo 'For a complete history reset, run: docker compose down --volumes'
