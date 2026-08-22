#!/usr/bin/env bash
#MISE description="Apply Talos config to a node (shows a diff and asks first)"
#MISE dir="talos"
#USAGE arg "<node>" help="Node name"
#USAGE arg "[mode]" default="auto" help="Apply mode" {
#USAGE   choices "auto" "reboot" "no-reboot" "staged" "try"
#USAGE }
set -euo pipefail

topf apply --nodes-filter "^${usage_node?}$" --mode "${usage_mode?}"
