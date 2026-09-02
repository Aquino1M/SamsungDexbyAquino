[CmdletBinding()]
param([string]$Uri)
$package = $null
try {
    Import-Module (Join-Path $PSScriptRoot 'Aquino.Gaming.psm1') -Force
    $package = [string](Get-AquinoForegroundPackage)
} catch {}
$args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Aquino-KeyMapper.ps1'),'-Mode','Gamepad')
if ($package) { $args += @('-Package',$package) }
Start-Process powershell.exe -ArgumentList $args
