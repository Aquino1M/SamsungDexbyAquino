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
if (-not (Test-Path $exe)) { throw "Android_Dex.exe nao encontrado em $exe" }

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

# Aquino Remote: bridge local para controlar o launcher pelo celular.
try {
    $remoteBridge = Join-Path $PSScriptRoot 'Aquino-RemoteBridge.ps1'
    if (-not (Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue | Where-Object CommandLine -like '*Aquino-RemoteBridge.ps1*')) {
        Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',$remoteBridge) -WindowStyle Hidden
        Log 'Aquino Remote Bridge iniciado na porta 37891.'
    }
} catch { Log "Aviso Remote Bridge: $($_.Exception.Message)" }

$process = Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe) -PassThru
Log "Android Dex iniciado imediatamente. PID=$($process.Id)"

$adb = Resolve-AquinoAdb -Root $root
if (-not $SkipAdbRepair) {
    Log 'Verificando ADB em segundo plano...'
    if (-not (Repair-AquinoAdb -AdbPath $adb -ForceCleanup:$ForceAdbCleanup)) {
        Log 'Aviso: ADB nao iniciou. O app original continuara aberto para diagnostico manual.'
    }
}

$serial = Wait-AquinoAuthorizedDevice -AdbPath $adb -TimeoutSeconds 15
if ($serial) {
    Log 'Dispositivo autorizado detectado.'
    if (Repair-AquinoReversePorts -Serial $serial -AdbPath $adb) {
        Log 'Portas reversas 3698-3702 prontas.'
    } else {
        Log 'Aviso: nao foi possivel preparar todas as portas reversas.'
    }
    try {
        $remoteApk = Join-Path $root 'Android_Dex\Build_copy\AquinoRemote.apk'
        if (Test-Path $remoteApk) {
            & $adb -s $serial install -r $remoteApk | Out-Null
            if ($LASTEXITCODE -eq 0) { Log 'Aquino Remote instalado/atualizado no Android.' }
        }
    } catch { Log "Aviso Aquino Remote APK: $($_.Exception.Message)" }
} else {
    Log 'Nenhum dispositivo autorizado detectado no pre-check rapido.'
}

if ($Fullscreen) {
    for ($i=0; $i -lt 30; $i++) {
        Start-Sleep -Milliseconds 300
        $process.Refresh()
        if ($process.MainWindowHandle -ne 0) { break }
    }
    try { Set-AquinoBorderlessFullscreen -Process $process; Log 'Tela cheia borderless aplicada.' }
    catch { Log "Nao foi possivel aplicar tela cheia: $($_.Exception.Message)" }
}

if (-not $NoMonitor) {
    while (-not $process.HasExited) {
        Start-Sleep -Seconds 5
        if (-not (Test-AquinoAdbServer -AdbPath $adb)) {
            Log 'ADB parou de responder. Tentando recuperacao automatica...'
            [void](Repair-AquinoAdb -AdbPath $adb -Retries 2 -ForceCleanup:$ForceAdbCleanup)
        }
        $process.Refresh()
    }
    Log "Android Dex encerrado com codigo $($process.ExitCode)."
}
