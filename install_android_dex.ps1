[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$InstallPath = (Join-Path $env:LOCALAPPDATA 'Android Dex by Aquino')
)

$ErrorActionPreference = 'Stop'
$version = 'v0.3.3'
$archiveName = 'Android_Dex_by_Aquino_Gaming_v0.3.3.zip'
$archiveUrl = "https://github.com/Aquino1M/SamsungDexbyAquino/releases/download/$version/$archiveName"
$expectedHash = 'F3E1E01EDDF9178E3DEA5A0D1C9742D801AACFE7A7CC17CFF209EBD94DAB633F'
$installPath = [IO.Path]::GetFullPath($InstallPath)

if (Test-Path -LiteralPath $installPath) {
    throw "A pasta de destino ja existe: $installPath. Escolha outro -InstallPath para preservar a instalacao atual."
}

if (-not $PSCmdlet.ShouldProcess($installPath, "Instalar Android Dex by Aquino $version")) { return }

$tempPath = Join-Path ([IO.Path]::GetTempPath()) ("android-dex-aquino-" + [guid]::NewGuid())
try {
    New-Item -ItemType Directory -Path $tempPath | Out-Null
    $archivePath = Join-Path $tempPath $archiveName
    Write-Host 'Baixando Android Dex by Aquino...'
    Invoke-WebRequest -Uri $archiveUrl -OutFile $archivePath

    $hash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
    if ($hash -ne $expectedHash) { throw 'A verificacao de integridade do download falhou.' }

    $extractPath = Join-Path $tempPath 'extract'
    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractPath
    $packagePath = Join-Path $extractPath 'Android_Dex_by_Aquino_Gaming_v0.3.2'
    $exePath = Join-Path $packagePath 'Android_Dex\Android_Dex.exe'
    if (-not (Test-Path -LiteralPath $exePath)) { throw 'O pacote baixado nao contem Android_Dex.exe.' }

    New-Item -ItemType Directory -Path $installPath | Out-Null
    Get-ChildItem -LiteralPath $packagePath -Force | Move-Item -Destination $installPath
    Write-Host "Instalado em: $installPath"
    Write-Host 'Abra start_android_dex.bat para iniciar o Android Dex.'
} finally {
    if (Test-Path -LiteralPath $tempPath) { Remove-Item -LiteralPath $tempPath -Recurse -Force }
}
