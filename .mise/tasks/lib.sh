#!/usr/bin/env bash
# Shared helpers for mise tasks. Sourced by task scripts, not a task itself.

# Log a message with a level and optional key/value fields. Replaces the
# `gum log` helper that the just-based tasks used to rely on.
#
#   log info "Applying CRDs" stage "apps-crds"
log() {
    local lvl="${1:-info}" msg="${2:-}"
    shift 2
    printf '%s %-7s %s' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${lvl}" "${msg}"
    for kv in "$@"; do
        printf ' %s' "${kv}"
    done
    printf '\n'
}

# Prompt for a [y/N] confirmation on stdin (works with `yes |`).
confirm() {
    local prompt="$1" ans
    printf '%s ' "${prompt}" >&2
    IFS= read -r ans
    [[ "${ans}" =~ ^[Yy]$ ]]
}
