#!/usr/bin/env bash
#MISE description="Encrypt any unencrypted sops secrets"
#MISE hide=true
#MISE depends=["template:render"]
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

while IFS= read -r -d '' f; do
    if ! status="$(sops filestatus "$f" | jq -r '.encrypted')"; then
        die "could not read encryption status" file "$f"
    fi
    case "$status" in
        false) sops encrypt --in-place "$f" ;;
        true)  : ;;
        *)     die "could not determine encryption status" file "$f" ;;
    esac
done < <(find "${MISE_CONFIG_ROOT}/bootstrap" "${MISE_CONFIG_ROOT}/kubernetes" "${MISE_CONFIG_ROOT}/talos" -type f -name '*.sops.*' -print0)
