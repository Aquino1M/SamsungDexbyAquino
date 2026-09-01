[CmdletBinding()]
param(
    [string]$Profile = 'default',
    [switch]$Fullscreen,
    [switch]$SkipAdbRepair,
    [switch]$ForceAdbCleanup,
    [switch]$NoMonitor
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AndroidDex.Aquino.psm1') -Force
$root = Get-AquinoRoot
$exe = Join-Path $root 'Android_Dex\Android_Dex.exe'
if (-not (Test-Path $exe)) { throw "Android_Dex.exe não encontrado em $exe" }

$logDir = Join-Path $root 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir 'aquino-launcher.log'
function Log([string]$message) {
    $line = "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $message"
    Add-Content -Path $log -Value $line -Encoding UTF8
    Write-Host $line
}

$profileObject = Set-AquinoActiveProfile -Name $Profile -Root $root
Log "Perfil ativo: $Profile (FPS=$($profileObject.video.fps), codec=$($profileObject.video.codec))"

$adb = Resolve-AquinoAdb -Root $root
if (-not $SkipAdbRepair) {
    Log 'Verificando ADB…'
    if (-not (Repair-AquinoAdb -AdbPath $adb -ForceCleanup:$ForceAdbCleanup)) {
        throw 'Não foi possível iniciar o ADB. Execute scripts\Diagnostics.ps1 para detalhes.'
    }
}

$serial = Wait-AquinoAuthorizedDevice -AdbPath $adb -TimeoutSeconds 45
if ($serial) {
    Log 'Dispositivo autorizado detectado.'
    if (Repair-AquinoReversePorts -Serial $serial -AdbPath $adb) {
        Log 'Portas reversas 3698–3702 prontas.'
    } else {
        Log 'Aviso: não foi possível preparar todas as portas reversas. A aplicação ainda será iniciada.'
    }
} else {
    Log 'Nenhum dispositivo autorizado em 45s. Iniciando a interface para permitir diagnóstico manual.'
}

$process = Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe) -PassThru
Log "Android Dex iniciado. PID=$($process.Id)"

if ($Fullscreen) {
    for ($i=0; $i -lt 30; $i++) {
        Start-Sleep -Milliseconds 300
        $process.Refresh()
        if ($process.MainWindowHandle -ne 0) { break }
    }
    try { Set-AquinoBorderlessFullscreen -Process $process; Log 'Tela cheia borderless aplicada.' }
    catch { Log "Não foi possível aplicar tela cheia: $($_.Exception.Message)" }
}

if (-not $NoMonitor) {
    while (-not $process.HasExited) {
        Start-Sleep -Seconds 5
        if (-not (Test-AquinoAdbServer -AdbPath $adb)) {
            Log 'ADB parou de responder. Tentando recuperação automática…'
            [void](Repair-AquinoAdb -AdbPath $adb -Retries 2 -ForceCleanup:$ForceAdbCleanup)
        }
        $process.Refresh()
    }
    Log "Android Dex encerrado com código $($process.ExitCode)."
}
