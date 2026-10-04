#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export KUBECONFIG="$PWD/.local/kubeconfig"
exec .local/bin/kubectl -n delivery-lab port-forward --address 127.0.0.1 service/delivery-lab 8081:8080
