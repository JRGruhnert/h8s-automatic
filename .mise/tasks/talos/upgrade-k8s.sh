#!/usr/bin/env bash
#MISE description="Upgrade Kubernetes"
#MISE dir="talos"
set -euo pipefail

# topf intentionally does not manage Kubernetes upgrades
talosctl --nodes "$(yq '[.nodes[] | select(.role == "control-plane")][0].ip' topf.yaml)" \
    upgrade-k8s --to "$(yq '.kubernetesVersion' topf.yaml)"
