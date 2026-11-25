#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <ply-path> [topic] [batch-size] [rate]" >&2
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROSPLAT_PLY="$1"
export ROSPLAT_TOPIC="${2:-/gaussian_test}"
export ROSPLAT_BATCH="${3:-500}"
export ROSPLAT_RATE="${4:-10}"

cd "$ROOT"
exec pixi run bash -lc '
  source install-ros/setup.bash
  python misc/generate_gaussian_bag.py \
    --ply-path "$ROSPLAT_PLY" \
    --topic "$ROSPLAT_TOPIC" \
    --batch-size "$ROSPLAT_BATCH" \
    --rate "$ROSPLAT_RATE"
'
