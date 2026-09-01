Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-AquinoRoot {
    param([string]$StartPath = $PSScriptRoot)
    return (Resolve-Path (Join-Path $StartPath '..')).Path
}

function Resolve-AquinoAdb {
    param([string]$Root = (Get-AquinoRoot))
    $candidates = @(
        (Join-Path $Root 'Android_Dex\Build_copy\adb-windows\adb.exe'),
        (Join-Path $Root 'Android_Dex\Build_copy\adb-windows\rec\adb.exe'),
        (Join-Path $Root 'platform-tools\adb.exe')
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) { return (Resolve-Path $candidate).Path }
    }
    $cmd = Get-Command adb.exe -ErrorAction SilentlyContinue
    if (-not $cmd) { $cmd = Get-Command adb -ErrorAction SilentlyContinue }
    if ($cmd) { return $cmd.Source }
    throw 'ADB não encontrado. Coloque a build Android_Dex na raiz ou instale Android platform-tools.'
}

function Invoke-AquinoAdb {
    param(
        [Parameter(Mandatory=$true)][string[]]$Arguments,
        [string]$AdbPath = (Resolve-AquinoAdb),
        [switch]$IgnoreExitCode
    )
    $output = & $AdbPath @Arguments 2>&1 | ForEach-Object { "$_" }
    $code = $LASTEXITCODE
    if (($code -ne 0) -and -not $IgnoreExitCode) {
        throw "ADB falhou (exit $code): $($output -join [Environment]::NewLine)"
    }
    [pscustomobject]@{ ExitCode = $code; Output = $output; Text = ($output -join [Environment]::NewLine) }
}

function Test-AquinoAdbServer {
    param([string]$AdbPath = (Resolve-AquinoAdb))
    try {
        $r = Invoke-AquinoAdb -AdbPath $AdbPath -Arguments @('devices') -IgnoreExitCode
        return ($r.ExitCode -eq 0 -and $r.Text -notmatch 'cannot connect to daemon')
    } catch { return $false }
}

function Repair-AquinoAdb {
    param(
        [string]$AdbPath = (Resolve-AquinoAdb),
        [int]$Retries = 3,
        [switch]$ForceCleanup
    )
    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        try { Invoke-AquinoAdb -AdbPath $AdbPath -Arguments @('kill-server') -IgnoreExitCode | Out-Null } catch {}
        Start-Sleep -Milliseconds 500
        $start = Invoke-AquinoAdb -AdbPath $AdbPath -Arguments @('start-server') -IgnoreExitCode
        if ($start.ExitCode -eq 0 -and (Test-AquinoAdbServer -AdbPath $AdbPath)) { return $true }
        Start-Sleep -Seconds $attempt
    }

    if ($ForceCleanup) {
        $wanted = [IO.Path]::GetFullPath($AdbPath).ToLowerInvariant()
        Get-CimInstance Win32_Process -Filter "Name='adb.exe'" -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.ExecutablePath -and ([IO.Path]::GetFullPath($_.ExecutablePath).ToLowerInvariant() -eq $wanted)) {
                Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            }
        }
        Start-Sleep -Milliseconds 500
        $retry = Invoke-AquinoAdb -AdbPath $AdbPath -Arguments @('start-server') -IgnoreExitCode
        return ($retry.ExitCode -eq 0 -and (Test-AquinoAdbServer -AdbPath $AdbPath))
    }
    return $false
}

function Get-AquinoDevices {
    param([string]$AdbPath = (Resolve-AquinoAdb))
    $r = Invoke-AquinoAdb -AdbPath $AdbPath -Arguments @('devices','-l') -IgnoreExitCode
    $devices = @()
    foreach ($line in $r.Output) {
        if ($line -match '^([^\s]+)\s+(device|unauthorized|offline|authorizing)(?:\s+(.*))?$') {
            $devices += [pscustomobject]@{ Serial=$matches[1]; State=$matches[2]; Details=$matches[3] }
        }
    }
    return $devices
}

function Wait-AquinoAuthorizedDevice {
    param(
        [string]$AdbPath = (Resolve-AquinoAdb),
        [int]$TimeoutSeconds = 45
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $devices = @(Get-AquinoDevices -AdbPath $AdbPath)
        $ready = $devices | Where-Object State -eq 'device' | Select-Object -First 1
        if ($ready) { return $ready.Serial }
        $blocked = $devices | Where-Object { $_.State -in @('unauthorized','authorizing') } | Select-Object -First 1
        if ($blocked) { Write-Host 'Aguardando você aceitar a autorização RSA no celular…' -ForegroundColor Yellow }
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)
    return $null
}

function Repair-AquinoReversePorts {
    param(
        [Parameter(Mandatory=$true)][string]$Serial,
        [string]$AdbPath = (Resolve-AquinoAdb),
        [int[]]$Ports = @(3698,3699,3700,3701,3702)
    )
    Invoke-AquinoAdb -AdbPath $AdbPath -Arguments @('-s',$Serial,'reverse','--remove-all') -IgnoreExitCode | Out-Null
    foreach ($port in $Ports) {
        $r = Invoke-AquinoAdb -AdbPath $AdbPath -Arguments @('-s',$Serial,'reverse',"tcp:$port","tcp:$port") -IgnoreExitCode
        if ($r.ExitCode -ne 0) { return $false }
    }
    return $true
}

function Get-AquinoGameProfiles {
    param([string]$Root = (Get-AquinoRoot))
    $path = Join-Path $Root 'config\game-profiles.json'
    if (-not (Test-Path $path)) { throw "Perfis não encontrados: $path" }
    return (Get-Content $path -Raw | ConvertFrom-Json)
}

function Set-AquinoActiveProfile {
    param(
        [string]$Name = 'default',
        [string]$Root = (Get-AquinoRoot)
    )
    $cfg = Get-AquinoGameProfiles -Root $Root
    $profile = $cfg.profiles.$Name
    if (-not $profile) { throw "Perfil desconhecido: $Name" }
    $runtime = Join-Path $Root 'runtime'
    New-Item -ItemType Directory -Force -Path $runtime | Out-Null
    $active = [ordered]@{ selected=$Name; selectedAt=(Get-Date).ToString('o'); profile=$profile }
    $active | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $runtime 'active-profile.json') -Encoding UTF8
    $env:ANDROID_DEX_PROFILE = $Name
    $env:ANDROID_DEX_TARGET_FPS = [string]$profile.video.fps
    $env:ANDROID_DEX_CODEC = [string]$profile.video.codec
    $env:ANDROID_DEX_LOW_LATENCY = [string]$profile.video.lowLatency
    return $profile
}

function Initialize-AquinoWin32 {
    if ('AquinoWin32' -as [type]) { return }
    Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class AquinoWin32 {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Auto)] public struct MONITORINFO { public int cbSize; public RECT rcMonitor; public RECT rcWork; public uint dwFlags; }
  [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
  [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
  [DllImport("user32.dll")] public static extern IntPtr MonitorFromWindow(IntPtr hwnd, uint dwFlags);
  [DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern bool GetMonitorInfo(IntPtr hMonitor, ref MONITORINFO lpmi);
}
'@
}

function Set-AquinoBorderlessFullscreen {
    param(
        [Parameter(Mandatory=$true)][System.Diagnostics.Process]$Process,
        [switch]$Off
    )
    Initialize-AquinoWin32
    $Process.Refresh()
    $handle = $Process.MainWindowHandle
    if ($handle -eq [IntPtr]::Zero) { throw 'A janela principal ainda não está disponível.' }
    $GWL_STYLE = -16
    $WS_OVERLAPPEDWINDOW = 0x00CF0000
    $SWP_FRAMECHANGED = 0x0020
    $SWP_NOZORDER = 0x0004
    $MONITOR_DEFAULTTONEAREST = 2

    if ($Off) {
        [AquinoWin32]::SetWindowLong($handle, $GWL_STYLE, $WS_OVERLAPPEDWINDOW) | Out-Null
        [AquinoWin32]::SetWindowPos($handle, [IntPtr]::Zero, 80, 80, 1280, 720, $SWP_FRAMECHANGED -bor $SWP_NOZORDER) | Out-Null
        return
    }

    [AquinoWin32]::SetWindowLong($handle, $GWL_STYLE, 0) | Out-Null
    $monitor = [AquinoWin32]::MonitorFromWindow($handle, $MONITOR_DEFAULTTONEAREST)
    $mi = New-Object AquinoWin32+MONITORINFO
    $mi.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($mi)
    [AquinoWin32]::GetMonitorInfo($monitor, [ref]$mi) | Out-Null
    $w = $mi.rcMonitor.Right - $mi.rcMonitor.Left
    $height = $mi.rcMonitor.Bottom - $mi.rcMonitor.Top
    [AquinoWin32]::SetWindowPos($handle, [IntPtr]::Zero, $mi.rcMonitor.Left, $mi.rcMonitor.Top, $w, $height, $SWP_FRAMECHANGED -bor $SWP_NOZORDER) | Out-Null
}

function Get-AquinoHealth {
    param([string]$Root = (Get-AquinoRoot))
    $items = @()
    $paths = [ordered]@{
        AndroidDexExe = (Join-Path $Root 'Android_Dex\Android_Dex.exe')
        CompanionApk = (Join-Path $Root 'Android_Dex\Build_copy\AndroidDex.apk')
        MainServerJar = (Join-Path $Root 'Android_Dex\Build_copy\AndroidDex-main-server.jar')
        AudioServerJar = (Join-Path $Root 'Android_Dex\Build_copy\AndroidDex-audio-server.jar')
        FlexDisplayJar = (Join-Path $Root 'Android_Dex\Build_copy\AndroidDex-flex-display-server.jar')
        VirtualDisplayJar = (Join-Path $Root 'Android_Dex\Build_copy\AndroidDex-vd-server.jar')
        Ffmpeg = (Join-Path $Root 'Android_Dex\ffmpeg.exe')
        WebView2Loader = (Join-Path $Root 'Android_Dex\WebView2Loader.dll')
    }
    foreach ($name in $paths.Keys) {
        $items += [pscustomobject]@{ Check=$name; Ok=(Test-Path $paths[$name]); Detail=$paths[$name] }
    }
    try {
        $adb = Resolve-AquinoAdb -Root $Root
        $items += [pscustomobject]@{ Check='ADB'; Ok=(Test-AquinoAdbServer -AdbPath $adb); Detail=$adb }
        $devices = @(Get-AquinoDevices -AdbPath $adb)
        $items += [pscustomobject]@{ Check='AuthorizedDevice'; Ok=([bool]($devices | Where-Object State -eq 'device')); Detail=(($devices | ForEach-Object { $_.State }) -join ',') }
    } catch {
        $items += [pscustomobject]@{ Check='ADB'; Ok=$false; Detail=$_.Exception.Message }
    }
    return $items
}

Export-ModuleMember -Function *-Aquino*
