#!/usr/bin/env bash
#MISE description="Reset all nodes back to maintenance mode (DESTRUCTIVE)"
#MISE dir="talos"
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

confirm "This will destroy your cluster and reset all nodes to maintenance mode — continue? [y/N]" || { log info "aborted"; exit 1; }

topf reset --confirm=false
