#!/usr/bin/env bash
#MISE description="Initialize configuration files (cluster.toml, age key, deploy key, webhook token)"
set -euo pipefail

ROOT="${MISE_CONFIG_ROOT}"

[ -f "${ROOT}/cluster.toml" ]            || cp "${ROOT}/cluster.sample.toml" "${ROOT}/cluster.toml"
[ -f "${SOPS_AGE_KEY_FILE}" ]            || age-keygen -pq --output "${SOPS_AGE_KEY_FILE}"
[ -f "${ROOT}/deploy.key" ]              || ssh-keygen -t ed25519 -C "deploy-key" -f "${ROOT}/deploy.key" -q -P ""
[ -f "${ROOT}/flux-webhook-token.txt" ]  || openssl rand -hex 16 > "${ROOT}/flux-webhook-token.txt"
