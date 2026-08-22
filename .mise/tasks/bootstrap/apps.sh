#!/usr/bin/env bash
#MISE description="Bootstrap apps into the Talos cluster"
#MISE depends=["bootstrap:apps-helm"]
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

log info "Cluster is bootstrapped — Flux will start syncing the Git repository"
