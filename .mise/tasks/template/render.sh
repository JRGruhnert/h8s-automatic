#!/usr/bin/env bash
#MISE description="Render templates with makejinja"
#MISE hide=true
set -euo pipefail

PYTHONDONTWRITEBYTECODE=1 uv run --locked --no-dev makejinja
