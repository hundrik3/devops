#!/usr/bin/env bash
set -euo pipefail
base=${1:?Usage: smoke.sh http://127.0.0.1:18080}
[[ $(curl -fsS --max-time 10 "$base/healthz") == ok ]]
[[ $(curl -fsS --max-time 10 "$base/readyz") == ok ]]
[[ $(curl -fsS --max-time 10 "$base/api/hello") == 'Hello, DevOps!' ]]
[[ $(curl -fsS --max-time 10 --get --data-urlencode 'name= Hundrik ' "$base/api/hello") == 'Hello, Hundrik!' ]]
curl -fsS --max-time 10 "$base/" | grep -q 'Java Delivery Lab'
long_name=$(printf '%081d' 0)
[[ $(curl -sS --max-time 10 -o /dev/null -w '%{http_code}' --get --data-urlencode "name=$long_name" "$base/api/hello") == 400 ]]
printf 'PASS: health, readiness, default greeting, named greeting, homepage, HTTP 400\n'
