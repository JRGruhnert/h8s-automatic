#!/usr/bin/env bash
#MISE description="Validate rendered Talos machine configs"
#MISE hide=true
#MISE dir="talos"
#MISE depends=["template:encrypt-secrets"]
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

# Rendering needs the secrets bundle; topf generates and sops-encrypts one
# on first run (--confirm=false so it never prompts mid-pipeline).
topf render --confirm=false --output "$(mktemp -d)" >/dev/null
if ! sops filestatus secrets.sops.yaml | jq --exit-status '.encrypted == true' >/dev/null; then
    die "Talos secrets bundle is not encrypted"
fi
