[CmdletBinding()]
param([string]$Root = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'AndroidDex.Aquino.psm1') -Force
$apk=Join-Path $Root 'Android_Dex\Build_copy\AquinoRemote.apk'
if(-not(Test-Path $apk)){Write-Host 'AquinoRemote.apk ainda nao esta no pacote. O codigo fonte esta em android/AquinoRemote.';exit 0}
$adb=Resolve-AquinoAdb -Root $Root
$serial=Wait-AquinoAuthorizedDevice -AdbPath $adb -TimeoutSeconds 20
if(-not $serial){throw 'Nenhum Android autorizado por ADB.'}
& $adb -s $serial install -r $apk
if($LASTEXITCODE -ne 0){throw 'Falha ao instalar Aquino Remote.'}
Write-Host 'Aquino Remote instalado/atualizado.'
