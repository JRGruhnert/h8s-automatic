#!/usr/bin/env bash
#MISE description="Validate rendered Kubernetes manifests"
#MISE hide=true
#MISE depends=["template:encrypt-secrets"]
set -euo pipefail

bash "${MISE_CONFIG_ROOT}/template/resources/kubeconform.sh" "${MISE_CONFIG_ROOT}/kubernetes"
