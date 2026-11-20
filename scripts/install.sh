#!/usr/bin/env bash
# Install the PowerShell release pinned in pwsh.pins and put it first on PATH.
#
# Environment: RUNNER_TEMP, GITHUB_PATH and GITHUB_OUTPUT (set by the runner),
# RUNNER_TOOL_CACHE (optional, defaults to RUNNER_TEMP), PINS_FILE (optional,
# defaults to the pins file next to this script's action).
set -euo pipefail

die() { printf 'setup-pwsh-action: %s\n' "$1" >&2; exit 1; }

for name in RUNNER_TEMP GITHUB_PATH GITHUB_OUTPUT; do
  [ -n "${!name:-}" ] || die "$name is not set"
done

pins="${PINS_FILE:-$(cd "$(dirname "$0")/.." && pwd)/pwsh.pins}"
[ -f "$pins" ] || die "pins file not found: $pins"

version=$(sed -n 's/^version=//p' "$pins")
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "invalid version in $pins: '$version'"

case "$(uname -s)" in
  Linux) os=linux ;;
  Darwin) os=osx ;;
  MINGW* | MSYS* | CYGWIN*) os=win ;;
  *) die "unsupported operating system: $(uname -s)" ;;
esac
case "$(uname -m)" in
  x86_64 | amd64) arch=x64 ;;
  aarch64 | arm64) arch=arm64 ;;
  *) die "unsupported architecture: $(uname -m)" ;;
esac

platform="$os-$arch"
expected=$(sed -n "s/^$platform=//p" "$pins")
[[ "$expected" =~ ^[0-9a-f]{64}$ ]] || die "no SHA-256 pinned for $platform in $pins"

if [ "$os" = win ]; then
  archive="PowerShell-$version-$platform.zip"
else
  archive="powershell-$version-$platform.tar.gz"
fi
url="https://github.com/PowerShell/PowerShell/releases/download/v$version/$archive"

download="$RUNNER_TEMP/$archive"
curl --fail --silent --show-error --location --retry 3 --output "$download" "$url"

if command -v sha256sum > /dev/null; then
  actual=$(sha256sum "$download" | cut -d' ' -f1)
else
  actual=$(shasum -a 256 "$download" | cut -d' ' -f1)
fi
if [ "$actual" != "$expected" ]; then
  rm -f "$download"
  die "checksum mismatch for $archive: expected $expected, got $actual"
fi

target="${RUNNER_TOOL_CACHE:-$RUNNER_TEMP}/pwsh/$version/$platform"
rm -rf "$target"
mkdir -p "$target"
if [ "$os" = win ]; then
  # Git Bash's tar cannot read zip archives; the runner's Windows PowerShell can.
  powershell.exe -NoProfile -NonInteractive -Command \
    "Expand-Archive -LiteralPath '$(cygpath -w "$download")' -DestinationPath '$(cygpath -w "$target")' -Force"
  path_entry=$(cygpath -w "$target")
else
  tar -xzf "$download" -C "$target"
  chmod +x "$target/pwsh"
  path_entry="$target"
fi
rm -f "$download"

printf '%s\n' "$path_entry" >> "$GITHUB_PATH"
printf 'version=%s\n' "$version" >> "$GITHUB_OUTPUT"
printf 'Installed PowerShell %s for %s in %s\n' "$version" "$platform" "$path_entry"
