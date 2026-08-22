#!/usr/bin/env bash
#MISE description="Remove rendered files (bootstrap/, kubernetes/, talos/, .sops.yaml)"
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

ROOT="${MISE_CONFIG_ROOT}"

confirm "Remove all templated files and directories — continue? [y/N]" || { log info "aborted"; exit 1; }

rm -rf "${ROOT}/bootstrap" "${ROOT}/kubernetes" "${ROOT}/talos" "${ROOT}/.sops.yaml"
