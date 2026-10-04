#!/usr/bin/env bash
set -euo pipefail
cd "${WORKSPACE:?Jenkins WORKSPACE is required}"
mkdir -p source
if [[ -n ${SOURCE_REPOSITORY:-} ]]; then
  [[ $SOURCE_REPOSITORY =~ ^https://github\.com/[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+(\.git)?$ ]] || { echo 'Use an HTTPS github.com repository without embedded credentials'; exit 1; }
  [[ ${SOURCE_BRANCH:-main} =~ ^[a-zA-Z0-9][a-zA-Z0-9_./-]*$ ]] || exit 1
  if [[ ! -d source/.git ]]; then git init source; fi
  if git -C source remote get-url origin >/dev/null 2>&1; then
    git -C source remote set-url origin "$SOURCE_REPOSITORY"
  else
    git -C source remote add origin "$SOURCE_REPOSITORY"
  fi
  git -C source fetch --depth=1 origin "${SOURCE_BRANCH:-main}"
  git -C source checkout --detach --force FETCH_HEAD
  # This path belongs exclusively to the Jenkins job, not to the user's checkout.
  git -C source clean -fd -e .local/ -e target/
else
  echo 'Building the mounted local source snapshot; no GitHub publication required.'
  tar -C /opt/lab --exclude=.git --exclude=.local --exclude=target --exclude=.env --exclude=jenkins/tools -cf - . | tar -C source -xf -
fi
fingerprint=$(cd source && { find src k8s scripts -type f -exec sha256sum {} +; sha256sum pom.xml Dockerfile .dockerignore; } | LC_ALL=C sort | sha256sum | cut -d' ' -f1)
if [[ ${FORCE_REBUILD:-false} != true ]] && [[ -f .last-successful-fingerprint && -f .last-successful-image ]]; then
  if [[ $fingerprint == "$(cat .last-successful-fingerprint)" ]] && [[ $(kubectl config current-context) == kind-portfolio ]]; then
    image=$(kubectl -n delivery-lab get deployment delivery-lab -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)
    available=$(kubectl -n delivery-lab get deployment delivery-lab -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)
    if [[ $image == "$(cat .last-successful-image)" && $available == 2 ]]; then
      echo 'UNCHANGED: retaining the last successful delivery and its artifacts; tests and rollout were not rerun.'
      exit 0
    fi
  fi
fi
bash source/scripts/ci.sh
printf '%s\n' "$fingerprint" > .last-successful-fingerprint
cp source/target/evidence/image.txt .last-successful-image
