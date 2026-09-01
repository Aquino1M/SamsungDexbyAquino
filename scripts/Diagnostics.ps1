[CmdletBinding()]
param([switch]$NoFile)
Import-Module (Join-Path $PSScriptRoot 'AndroidDex.Aquino.psm1') -Force
$root = Get-AquinoRoot
$checks = @(Get-AquinoHealth -Root $root)
$checks | Format-Table -AutoSize

$adbDevices = @()
try {
    $adb = Resolve-AquinoAdb -Root $root
    foreach ($d in @(Get-AquinoDevices -AdbPath $adb)) {
        $bytes = [Text.Encoding]::UTF8.GetBytes($d.Serial)
        $sha = [Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
        $short = ([BitConverter]::ToString($sha).Replace('-','').Substring(0,10)).ToLowerInvariant()
        $adbDevices += [ordered]@{ id="device-$short"; state=$d.State; details=$d.Details }
    }
} catch {}

$report = [ordered]@{
    project = 'Android Dex by Aquino'
    author = 'Aquino / Aquino1M'
    generatedAt = (Get-Date).ToString('o')
    windows = [Environment]::OSVersion.VersionString
    powershell = $PSVersionTable.PSVersion.ToString()
    checks = $checks
    devices = $adbDevices
    reversePorts = @(3698,3699,3700,3701,3702)
    privacy = 'Device serial numbers are SHA-256 masked in this report.'
}

if (-not $NoFile) {
    $dir = Join-Path $root 'diagnostics'
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $path = Join-Path $dir ("diagnostics-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $report | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding UTF8
    Write-Host "`nRelatório salvo em: $path" -ForegroundColor Green
}
