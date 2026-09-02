[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Root)
$ErrorActionPreference='Stop'
$rootPath=[IO.Path]::GetFullPath($Root)
$script=Join-Path $rootPath 'scripts\Aquino-GamepadEditor.ps1'
if(-not(Test-Path -LiteralPath $script)){throw "Aquino-GamepadEditor.ps1 nao encontrado: $script"}
$key='HKCU:\Software\Classes\aquino-gamepad'
New-Item -Path $key -Force | Out-Null
Set-Item -Path $key -Value 'URL:Aquino Gamepad Editor'
New-ItemProperty -Path $key -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
$commandKey=Join-Path $key 'shell\open\command'
New-Item -Path $commandKey -Force | Out-Null
$command='"powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "'+$script+'" "%1"'
Set-Item -Path $commandKey -Value $command
