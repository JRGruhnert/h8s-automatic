#!/usr/bin/env bash
#MISE description="Show pending config changes without applying them"
#MISE dir="talos"
set -euo pipefail

topf apply --dry-run
