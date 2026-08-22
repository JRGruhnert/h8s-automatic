#!/usr/bin/env bash
#MISE description="Render the bootstrap helmfile charts against the rendered values"
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

helmfile --file "${MISE_CONFIG_ROOT}/bootstrap/helmfile/apps.yaml" template --quiet > /dev/null
log info "bootstrap charts rendered cleanly"
