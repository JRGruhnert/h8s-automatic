#!/usr/bin/env bash
#MISE description="Apply secrets for apps"
#MISE hide=true
#MISE dir="bootstrap"
#MISE depends=["bootstrap:apps-namespaces"]
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

log info "Applying secrets for apps" stage "apps-secrets"
for secret in \
    "deploy-key.sops.yaml" \
    "sops-age.sops.yaml" \
    "${MISE_CONFIG_ROOT}/kubernetes/components/sops/cluster-secrets.sops.yaml"
do
    name="$(basename "$secret" .sops.yaml)"
    if sops decrypt "$secret" \
            | kubectl --namespace flux-system apply --server-side --filename - &>/dev/null; then
        log info "Secret applied" resource "$name"
    else
        die "Failed to apply secret" resource "$name"
    fi
done
