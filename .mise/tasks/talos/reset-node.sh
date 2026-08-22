#!/usr/bin/env bash
#MISE description="Reset a single node back to maintenance mode (DESTRUCTIVE)"
#MISE dir="talos"
#USAGE arg "<node>" help="Node name"
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

confirm "This will reset node ${usage_node?} to maintenance mode — continue? [y/N]" || { log info "aborted"; exit 1; }

topf reset --nodes-filter "^${usage_node?}$" --confirm=false
