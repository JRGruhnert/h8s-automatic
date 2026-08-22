#!/usr/bin/env bash
#MISE description="Force Flux to pull in changes from your Git repository"
set -euo pipefail

flux --namespace flux-system reconcile kustomization flux-system --with-source
