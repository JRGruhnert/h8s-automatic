#!/usr/bin/env bash
#MISE description="Apply Talos config and bootstrap"
#MISE hide=true
#MISE dir="talos"
#MISE depends=["bootstrap:talos-secret"]
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

log info "Applying talos config and bootstrapping" stage "talos-apply"
topf apply --auto-bootstrap --confirm=false
