#!/usr/bin/env bash
#MISE description="Wait until nodes register as Ready"
#MISE hide=true
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

# Wait until nodes register as Ready=False. They only become Ready=True once the CNI is healthy.
log info "Waiting for nodes to register as Ready=False" stage "apps-ready"
if ! kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then
    deadline=$((SECONDS + 600))
    until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do
        if (( SECONDS >= deadline )); then
            die "Timed out waiting for nodes to register"
        fi
        log info "Nodes not available, waiting for nodes to be available. Retrying in 5 seconds..."
        sleep 5
    done
fi
