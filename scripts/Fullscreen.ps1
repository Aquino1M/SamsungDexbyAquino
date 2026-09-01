[CmdletBinding()]
param(
    [string]$ProcessName = 'Android_Dex',
    [switch]$Off
)
Import-Module (Join-Path $PSScriptRoot 'AndroidDex.Aquino.psm1') -Force
$processes = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Where-Object MainWindowHandle -ne 0)
if (-not $processes) { throw "Nenhuma janela encontrada para o processo '$ProcessName'." }
foreach ($p in $processes) {
    Set-AquinoBorderlessFullscreen -Process $p -Off:$Off
    Write-Host "Aquino fullscreen: $($p.ProcessName) PID=$($p.Id) Off=$Off"
}
