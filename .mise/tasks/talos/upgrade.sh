#!/usr/bin/env bash
#MISE description="Upgrade Talos on all nodes, one at a time (asks first)"
#MISE dir="talos"
set -euo pipefail

topf upgrade
