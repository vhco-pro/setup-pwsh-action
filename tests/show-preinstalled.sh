#!/usr/bin/env bash
# Print the runner's own PowerShell before the action runs, so the test log shows
# that the pinned release replaced it.
set -euo pipefail
if command -v pwsh > /dev/null; then
  # shellcheck disable=SC2016 # $PSVersionTable is PowerShell's, not the shell's.
  printf 'Preinstalled pwsh: %s at %s\n' "$(pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')" "$(command -v pwsh)"
else
  printf 'No preinstalled pwsh\n'
fi
