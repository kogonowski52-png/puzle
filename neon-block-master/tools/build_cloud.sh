#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/cloud_env.sh
command -v godot >/dev/null
javac -version
# These paths are prepared in the cloud snapshot; see docs/ANDROID.md on a new machine.
test -f "$XDG_DATA_HOME/godot/export_templates/4.6.3.stable/android_source.zip"
if [ ! -f android/build/build.gradle ]; then
  mkdir -p android/build
  unzip -q "$XDG_DATA_HOME/godot/export_templates/4.6.3.stable/android_source.zip" -d android/build
  printf '4.6.3.stable\n' > android/.build_version
  touch android/build/.gdignore
fi
python3 tools/build_android_runtime.py
python3 tools/build_diagnostics.py
godot --headless --path . --editor --import --quit
./tools/test.sh
godot --headless --path . --export-debug "Android APK"
godot --headless --path . --export-debug "Android AAB"
godot --headless --path . --export-release "Android AAB unsigned"
python3 tools/verify_artifacts.py
