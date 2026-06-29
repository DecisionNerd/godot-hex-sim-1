#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json "$@"
