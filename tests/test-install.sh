#!/usr/bin/env bash
# Behaviour tests for scripts/install.sh on the machine running them (Linux or macOS).
# They download the pinned PowerShell archive, so they need network access.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
INSTALL="$ROOT/scripts/install.sh"
PINS="$ROOT/pwsh.pins"
failures=0

fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
pass() { printf 'ok: %s\n' "$1"; }

new_runner() {
  RUNNER=$(mktemp -d)
  mkdir -p "$RUNNER/temp" "$RUNNER/tools"
  : > "$RUNNER/path"
  : > "$RUNNER/output"
}

run_install() {
  GITHUB_PATH="$RUNNER/path" GITHUB_OUTPUT="$RUNNER/output" \
    RUNNER_TEMP="$RUNNER/temp" RUNNER_TOOL_CACHE="$RUNNER/tools" \
    PINS_FILE="$1" bash "$INSTALL"
}

pinned_version=$(sed -n 's/^version=//p' "$PINS")

# A checksum that does not match fails before PATH changes.
new_runner
sed -E 's/^((linux|osx|win)-(x64|arm64))=.*/\1=0000000000000000000000000000000000000000000000000000000000000000/' "$PINS" > "$RUNNER/bad.pins"
if run_install "$RUNNER/bad.pins" > "$RUNNER/log" 2>&1; then
  fail 'wrong checksum: install succeeded'
elif [ -s "$RUNNER/path" ]; then
  fail 'wrong checksum: GITHUB_PATH was written'
elif ! grep -q 'checksum' "$RUNNER/log"; then
  fail 'wrong checksum: the error does not name the checksum'
else
  pass 'wrong checksum fails before PATH changes'
fi
rm -rf "$RUNNER"

# The right checksum installs the pinned version and exposes it.
new_runner
if ! run_install "$PINS" > "$RUNNER/log" 2>&1; then
  cat "$RUNNER/log"
  fail 'pinned install failed'
else
  dir=$(head -n 1 "$RUNNER/path")
  # shellcheck disable=SC2016 # $PSVersionTable is PowerShell's, not the shell's.
  reported=$("$dir/pwsh" -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')
  if [ "$reported" != "$pinned_version" ]; then
    fail "pwsh reports $reported, pin is $pinned_version"
  elif ! grep -qx "version=$pinned_version" "$RUNNER/output"; then
    fail 'the version output is missing'
  else
    pass "pinned install reports $pinned_version and sets the version output"
  fi
fi
rm -rf "$RUNNER"

if [ "$failures" -gt 0 ]; then
  printf '%s test(s) failed\n' "$failures"
  exit 1
fi
printf 'all tests passed\n'
