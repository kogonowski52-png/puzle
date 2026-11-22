#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Keep test progress isolated from the real player's save.
test_data=$(mktemp -d)
trap 'rm -rf "$test_data"' EXIT
XDG_DATA_HOME="$test_data" timeout 180s godot --headless --path . --script tests/run.gd
XDG_DATA_HOME="$test_data/billing" timeout 60s godot --headless --path . --script tests/billing.gd
python3 -m unittest discover -s tests -p 'test_*.py'
