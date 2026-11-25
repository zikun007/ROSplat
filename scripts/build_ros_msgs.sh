#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

exec pixi run bash -lc '
  colcon build --base-paths gaussian_interface \
    --packages-select gaussian_interface \
    --build-base build-ros --install-base install-ros \
    --event-handlers console_direct+
'
