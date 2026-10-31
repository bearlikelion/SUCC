#!/usr/bin/env bash
# Godot exits 0 after a script error, so the log is checked as well as the exit code.
set -euo pipefail

cd "$(dirname "$0")/.."
godot_bin="${GODOT:-godot}"
log="$(mktemp)"
trap 'rm -f "$log"' EXIT

# Registers new class_name scripts; its warnings are about the docs build folders, not SUCC.
"$godot_bin" --headless --path . --import > /dev/null 2>&1
"$godot_bin" --headless --path . -s res://tests/succ_replay_test.gd 2>&1 | tee "$log"
"$godot_bin" --headless --path . --quit-after 120 res://addons/SUCC/demo/test_level.tscn 2>&1 \
	| tee -a "$log"

if grep -E "SCRIPT ERROR|Parse Error|Failed to load script|ERROR:|WARNING:" "$log"; then
	echo "Errors or warnings found in the Godot log" >&2
	exit 1
fi
