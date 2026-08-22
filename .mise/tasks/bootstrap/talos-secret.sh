#!/usr/bin/env bash
#MISE description="Generate Talos secrets bundle"
#MISE hide=true
#MISE dir="talos"
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

log info "Generating secrets" stage "talos-secret"
topf secrets --confirm=false > /dev/null
