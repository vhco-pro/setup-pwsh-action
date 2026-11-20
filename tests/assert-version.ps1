# Fails unless the PowerShell running this script is the version the action installed.
param(
    [Parameter(Mandatory = $true)]
    [string]$Expected
)

$actual = $PSVersionTable.PSVersion.ToString()
$source = (Get-Process -Id $PID).Path
if ($actual -ne $Expected) {
    throw "pwsh steps run PowerShell $actual from $source; the action installed $Expected"
}
Write-Output "pwsh steps run PowerShell $actual from $source"
