#!/usr/bin/env bash
# Release workflow: installs the APK on the emulator, starts Vinyasa and checks
# it is still up 20 s later with no crash or startup failure in the log.
# Leaves a screenshot and the log in $1.
set -euo pipefail

out=${1:-smoke}
mkdir -p "$out"
apk=$(ls dist/*.apk | head -n1)
adb install -r "$apk"
adb logcat -c
adb shell am start -W -n dev.brahma.vinyasa/.MainActivity
sleep 20
adb exec-out screencap -p >"$out/android.png" || true
adb logcat -d >"$out/logcat.txt" || true

if ! adb shell pidof dev.brahma.vinyasa >/dev/null; then
  grep -E 'AndroidRuntime|FATAL|flutter' "$out/logcat.txt" | tail -80 || true
  echo "::error::Vinyasa is not running 20 s after it started"
  exit 1
fi
if grep -qE 'FATAL EXCEPTION|Unhandled Exception|Vinyasa startup failed' "$out/logcat.txt"; then
  grep -E -A20 'FATAL EXCEPTION|Unhandled Exception|Vinyasa startup failed' "$out/logcat.txt" | head -80
  echo "::error::Vinyasa failed at start"
  exit 1
fi
grep -E ' flutter ' "$out/logcat.txt" | tail -20 || true
echo "Vinyasa is up on the emulator"
