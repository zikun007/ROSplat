#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

exec pixi run bash -lc '
  source install-ros/setup.bash
  PYTHONPATH="$PWD:$PYTHONPATH" python -m rosplat.main
'
