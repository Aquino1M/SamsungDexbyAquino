[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet('pair','connect','disconnect','status')][string]$Action,
    [string]$Address,
    [string]$PairCode
)
Import-Module (Join-Path $PSScriptRoot 'AndroidDex.Aquino.psm1') -Force
$adb = Resolve-AquinoAdb
if (-not (Repair-AquinoAdb -AdbPath $adb)) { throw 'ADB indisponível.' }

switch ($Action) {
    'pair' {
        if (-not $Address -or -not $PairCode) { throw 'Use -Address IP:PORTA e -PairCode CÓDIGO.' }
        $r = Invoke-AquinoAdb -AdbPath $adb -Arguments @('pair',$Address,$PairCode) -IgnoreExitCode
        $r.Output | ForEach-Object { Write-Host $_ }
        if ($r.ExitCode -ne 0) { exit $r.ExitCode }
    }
    'connect' {
        if (-not $Address) { throw 'Use -Address IP:PORTA.' }
        $r = Invoke-AquinoAdb -AdbPath $adb -Arguments @('connect',$Address) -IgnoreExitCode
        $r.Output | ForEach-Object { Write-Host $_ }
        if ($r.ExitCode -ne 0) { exit $r.ExitCode }
    }
    'disconnect' {
        $args = @('disconnect')
        if ($Address) { $args += $Address }
        $r = Invoke-AquinoAdb -AdbPath $adb -Arguments $args -IgnoreExitCode
        $r.Output | ForEach-Object { Write-Host $_ }
    }
    'status' {
        Get-AquinoDevices -AdbPath $adb | Format-Table -AutoSize
    }
}
