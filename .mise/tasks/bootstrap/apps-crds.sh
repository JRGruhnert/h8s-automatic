#!/usr/bin/env bash
#MISE description="Apply CRDs"
#MISE hide=true
#MISE dir="bootstrap"
#MISE depends=["bootstrap:apps-secrets"]
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

log info "Applying CRDs" stage "apps-crds"
if ! helmfile --file "helmfile/crds.yaml" template --quiet | yq eval-all --exit-status 'select(.kind == "CustomResourceDefinition")' | kubectl apply --server-side --force-conflicts --filename -; then
    die "Failed to apply crds"
fi
