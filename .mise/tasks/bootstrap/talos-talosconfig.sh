#!/usr/bin/env bash
#MISE description="Generate talosconfig"
#MISE hide=true
#MISE dir="talos"
#MISE depends=["bootstrap:talos-apply"]
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

log info "Generating talosconfig" stage "talos-talosconfig"
topf talosconfig > talosconfig
