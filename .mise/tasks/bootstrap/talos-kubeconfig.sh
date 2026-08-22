#!/usr/bin/env bash
#MISE description="Fetch kubeconfig"
#MISE hide=true
#MISE dir="talos"
#MISE depends=["bootstrap:talos-talosconfig"]
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

log info "Fetching kubeconfig" stage "talos-kubeconfig"
# topf issues short-lived admin certs by default; 8760h keeps the
# kubeconfig usable long-term.
topf kubeconfig --validity 8760h > "${MISE_CONFIG_ROOT}/kubeconfig"
