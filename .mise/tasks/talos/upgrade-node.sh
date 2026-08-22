#!/usr/bin/env bash
#MISE description="Upgrade Talos on a single node (asks first)"
#MISE dir="talos"
#USAGE arg "<node>" help="Node name"
set -euo pipefail

topf upgrade --nodes-filter "^${usage_node?}$"
