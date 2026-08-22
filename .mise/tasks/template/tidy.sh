#!/usr/bin/env bash
#MISE description="Archive all template tooling under .private/<ts>/ (one-way, run after configure works)"
set -euo pipefail

source "${MISE_CONFIG_ROOT}/.mise/tasks/lib.sh"

ROOT="${MISE_CONFIG_ROOT}"

confirm "All template related config will be archived — continue? [y/N]" || { log info "aborted"; exit 1; }

log info "Checking preconditions" stage "tidy-preconditions"
test -d "${ROOT}/template"
test -d "${ROOT}/.github/template-tests"
test -f "${ROOT}/makejinja.toml"
test -f "${ROOT}/cluster.toml"
test -f "${ROOT}/cluster.sample.toml"
test -f "${ROOT}/pyproject.toml"
test -f "${ROOT}/uv.lock"
test -d "${ROOT}/.mise/tasks/template"
test -f "${ROOT}/.mise/config.toml"
test -f "${ROOT}/.renovaterc.json5"
compgen -G "${ROOT}/.github/workflows/template-*.yaml" > /dev/null

log info "Stripping template markers" stage "tidy-strip"
sd '\..\.jinja'                 '' "${ROOT}/.renovaterc.json5"
sd -A '.*required:template.*\n' '' "${ROOT}/.mise/config.toml"

log info "Archiving template tooling" stage "tidy-archive"
TIDY_FOLDER="${ROOT}/.private/$(date +%s)"
mkdir -p "${TIDY_FOLDER}"
rm -rf "${ROOT}/.github/template-tests" "${ROOT}/.github/workflows"/template-*.yaml
mv \
    "${ROOT}/template" \
    "${ROOT}/makejinja.toml" \
    "${ROOT}/cluster.toml" \
    "${ROOT}/cluster.sample.toml" \
    "${ROOT}/pyproject.toml" \
    "${ROOT}/uv.lock" \
    "${TIDY_FOLDER}/"
rm -rf "${ROOT}/.venv"
rm -rf "${ROOT}/.mise/tasks/template"
