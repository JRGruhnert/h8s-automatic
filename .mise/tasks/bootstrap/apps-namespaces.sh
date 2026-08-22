#!/usr/bin/env bash
#MISE description="Apply namespaces for apps"
#MISE hide=true
#MISE depends=["bootstrap:apps-ready"]
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

log info "Applying namespaces for apps" stage "apps-namespaces"
for app in "${MISE_CONFIG_ROOT}/kubernetes/apps"/*/; do
    ns="$(basename "$app")"
    if kubectl create namespace "$ns" --dry-run=client -o yaml \
            | kubectl apply --server-side --filename - &>/dev/null; then
        log info "Namespace applied" namespace "$ns"
    else
        die "Failed to apply namespace" namespace "$ns"
    fi
done
