#!/usr/bin/env bash
#MISE description="Apply Talos config to all nodes (shows a diff and asks first)"
#MISE dir="talos"
set -euo pipefail

topf apply
