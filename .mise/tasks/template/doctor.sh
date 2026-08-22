#!/usr/bin/env bash
#MISE description="Check that all prerequisite files exist and cluster.toml validates against the schema"
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

ROOT="${MISE_CONFIG_ROOT}"
rc=0

check() {
    local label="$1" path="$2"
    if [ -e "${path}" ]; then
        log info "ok" file "${label}"
    else
        log error "missing" file "${label}"
        rc=1
    fi
}

check "cluster.toml"           "${ROOT}/cluster.toml"
check "cluster.sample.toml"    "${ROOT}/cluster.sample.toml"

config_json="$(uv run --quiet --locked --no-dev "${ROOT}/template/scripts/validate.py" "${ROOT}/cluster.toml" 2>/dev/null || true)"

if [ "$(jq -r '.ingress.mode' <<< "$config_json" 2>/dev/null)" = "cloudflare-tunnel" ]; then
    check "cloudflare-tunnel.json" "${ROOT}/cloudflare-tunnel.json"
fi

check "age.key"                "${SOPS_AGE_KEY_FILE}"
check "deploy.key"             "${ROOT}/deploy.key"
check "flux-webhook-token.txt" "${ROOT}/flux-webhook-token.txt"
check "template/"              "${ROOT}/template"
check "makejinja.toml"         "${ROOT}/makejinja.toml"
check "validate.py"            "${ROOT}/template/scripts/validate.py"

if [ -f "${ROOT}/cluster.toml" ] && [ -f "${ROOT}/template/scripts/validate.py" ]; then
    if [ -n "$config_json" ]; then
        log info "ok" check schema
    else
        log error "fail" check schema
        log info "diagnose with: uv run --locked --no-dev ${ROOT}/template/scripts/validate.py ${ROOT}/cluster.toml"
        rc=1
    fi
fi

[ "$rc" = 0 ] && log info "all good"
exit "$rc"
