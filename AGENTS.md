# Repository instructions

Follow the relevant routes in
https://github.com/vhco-pro/docs/blob/0c108237fcd004e8636c0a2ca191436abd7bb7bd/AGENTS.md,
including the GitHub Actions convention for this repository's action and workflows.

This composite action installs one pinned, checksum-verified PowerShell release and puts it
first on `PATH`. It owns the PowerShell version for every action that calls it; it does not run
checks, build or publish anything.

Run `bash tests/test-install.sh` on Linux or macOS with network access. `test.yml` runs it on
both, runs the action itself on Linux x64 and arm64, macOS and Windows, and lints the workflows
and scripts.

When Renovate bumps `version=` in `pwsh.pins`, refresh every checksum in the same change from the
release's `hashes.sha256` asset before merging.
