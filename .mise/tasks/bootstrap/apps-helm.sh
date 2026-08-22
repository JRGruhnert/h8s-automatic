#!/usr/bin/env bash
#MISE description="Sync the helmfile apps"
#MISE hide=true
#MISE dir="bootstrap"
#MISE depends=["bootstrap:apps-crds"]
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

log info "Syncing helmfile" stage "apps-helm"
if ! helmfile --file "helmfile/apps.yaml" sync --hide-notes; then
    die "Failed to sync helmfile"
fi
