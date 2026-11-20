# setup-pwsh-action

Install a pinned PowerShell release on a GitHub Actions runner, verified by its SHA-256, and put
it first on `PATH`. Every later `shell: pwsh` step in the job runs that release instead of the
runner's preinstalled one.

This is the PowerShell counterpart of `actions/setup-go`. Actions that need PowerShell call it
instead of installing PowerShell themselves, so the version is pinned in one place.

```yaml
steps:
  - uses: vhco-pro/setup-pwsh-action@FULL_COMMIT_SHA # vX.Y.Z
    id: pwsh
  - shell: pwsh
    run: $PSVersionTable.PSVersion
```

Replace the placeholder with a released commit and its tag.

## Inputs and outputs

The action has no inputs. A caller chooses the PowerShell version by choosing a release of this
action.

| Output | Value |
| --- | --- |
| `version` | The PowerShell version installed, such as `7.7.0` |

## Platforms

Linux x64 and arm64, macOS x64 and arm64, and Windows x64 and arm64. The action downloads the
release archive from `github.com/PowerShell/PowerShell`, so the runner needs access to GitHub.
On Windows it extracts the archive with the runner's Windows PowerShell.

## Version and checksums

[`pwsh.pins`](pwsh.pins) holds the version and one SHA-256 per platform archive. The action
refuses an archive whose checksum differs and leaves `PATH` unchanged. Renovate proposes new
PowerShell releases through a custom manager; refresh every checksum in the same PR from the
release's `hashes.sha256` asset.

## Tests

`bash tests/test-install.sh` runs the install script on the current machine: a wrong checksum
must fail before `PATH` changes, and the pinned install must report the pinned version.
[`test.yml`](.github/workflows/test.yml) runs those tests on Linux and macOS, runs the action on
every platform and checks that `pwsh` steps report the pinned version, and lints the workflows
and scripts.
