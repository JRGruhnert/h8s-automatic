#!/usr/bin/env bash
#MISE description="Render Talos machine configs to ./rendered"
#MISE dir="talos"
set -euo pipefail

topf render --output ./rendered
