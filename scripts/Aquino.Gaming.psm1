Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AndroidDex.Aquino.psm1') -Force

function Resolve-AquinoScrcpy {
    param([string]$Root = (Get-AquinoRoot))
    $candidates = @(
        (Join-Path $Root 'Android_Dex\Build_copy\adb-windows\scrcpy.exe'),
        (Join-Path $Root 'Android_Dex\Build_copy\adb-windows\rec\scrcpy.exe'),
        (Join-Path $Root 'scrcpy\scrcpy.exe')
    )
    foreach ($candidate in $candidates) { if (Test-Path $candidate) { return (Resolve-Path $candidate).Path } }
    $cmd = Get-Command scrcpy.exe -ErrorAction SilentlyContinue
    if (-not $cmd) { $cmd = Get-Command scrcpy -ErrorAction SilentlyContinue }
    if ($cmd) { return $cmd.Source }
    throw 'scrcpy não encontrado. Coloque a build Android_Dex na raiz ou instale scrcpy.'
}
function Get-AquinoScrcpyVersion {
    param([string]$ScrcpyPath = (Resolve-AquinoScrcpy))
    try { $text = (& $ScrcpyPath --version 2>&1 | ForEach-Object { "$_" }) -join "`n"; if ($text -match 'scrcpy\s+([0-9]+(?:\.[0-9]+){1,2})') { return $matches[1] }; return $text.Trim() } catch { return 'unknown' }
}
function Get-AquinoInstalledApps {
    param([string]$AdbPath = (Resolve-AquinoAdb), [switch]$IncludeSystem)
    $args = @('shell','cmd','package','list','packages'); if (-not $IncludeSystem) { $args += '-3' }
    $r = Invoke-AquinoAdb -AdbPath $AdbPath -Arguments $args -IgnoreExitCode
    @($r.Output | ForEach-Object { if ($_ -match '^package:(.+)$') { $matches[1].Trim() } } | Where-Object { $_ } | Sort-Object -Unique)
}
function Get-AquinoForegroundPackage {
    param([string]$AdbPath = (Resolve-AquinoAdb))
    foreach ($query in @(@('shell','dumpsys','window','windows'),@('shell','dumpsys','activity','activities'))) {
        $r=Invoke-AquinoAdb -AdbPath $AdbPath -Arguments $query -IgnoreExitCode
        foreach($line in $r.Output){ if($line -match '(?:mCurrentFocus|mResumedActivity).*?\s([A-Za-z0-9_\.]+)/(?:[A-Za-z0-9_\.$]+)'){return $matches[1]} }
    }
    return $null
}
function Get-AquinoScrcpyEncoders {
    param([string]$ScrcpyPath = (Resolve-AquinoScrcpy))
    try { @(& $ScrcpyPath --list-encoders 2>&1 | ForEach-Object { "$_" }) } catch { @() }
}
function Resolve-AquinoVideoCodec {
    param([ValidateSet('auto','h264','h265','av1','vp8','vp9')][string]$Preferred='auto',[string]$ScrcpyPath=(Resolve-AquinoScrcpy))
    if($Preferred -ne 'auto'){return $Preferred}; $e=(Get-AquinoScrcpyEncoders -ScrcpyPath $ScrcpyPath)-join "`n"
    foreach($c in @('av1','h265','h264','vp9','vp8')){if($e -match [regex]::Escape($c)){return $c}}; 'h264'
}

function Initialize-AquinoGameWindowInterop {
    if ('AquinoGameWindowNative' -as [type]) { return }
    Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class AquinoGameWindowNative {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern IntPtr SetParent(IntPtr hWndChild, IntPtr hWndNewParent);
    [DllImport("user32.dll", EntryPoint="GetWindowLongPtr")] public static extern IntPtr GetWindowLongPtr64(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll", EntryPoint="SetWindowLongPtr")] public static extern IntPtr SetWindowLongPtr64(IntPtr hWnd, int nIndex, IntPtr dwNewLong);
    [DllImport("user32.dll", EntryPoint="GetWindowLong")] public static extern int GetWindowLong32(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll", EntryPoint="SetWindowLong")] public static extern int SetWindowLong32(IntPtr hWnd, int nIndex, int dwNewLong);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int x, int y, int width, int height, bool repaint);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
    public static long GetStyle(IntPtr hWnd) { return IntPtr.Size == 8 ? GetWindowLongPtr64(hWnd,-16).ToInt64() : GetWindowLong32(hWnd,-16); }
    public static void SetStyle(IntPtr hWnd,long style) { if(IntPtr.Size==8) SetWindowLongPtr64(hWnd,-16,new IntPtr(style)); else SetWindowLong32(hWnd,-16,(int)style); }
}
'@
}
function Get-AquinoDexProcess {
    @(Get-Process Android_Dex -ErrorAction SilentlyContinue | Where-Object MainWindowHandle -ne 0 | Sort-Object StartTime -Descending | Select-Object -First 1)[0]
}
function Embed-AquinoGameWindow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][System.Diagnostics.Process]$Process,
        [int]$TopMargin = 72,
        [int]$BottomMargin = 58,
        [int]$SideMargin = 22
    )
    Initialize-AquinoGameWindowInterop
    $dex = Get-AquinoDexProcess
    if (-not $dex) { throw 'Android Dex não está aberto. Inicie Android_Dex_by_Aquino.exe primeiro.' }
    try { $Process.WaitForInputIdle(10000) | Out-Null } catch {}
    $deadline = (Get-Date).AddSeconds(15)
    do {
        $Process.Refresh()
        if ($Process.HasExited) { throw 'scrcpy encerrou antes de criar a janela do jogo.' }
        if ($Process.MainWindowHandle -ne [IntPtr]::Zero) { break }
        Start-Sleep -Milliseconds 120
    } while ((Get-Date) -lt $deadline)
    if ($Process.MainWindowHandle -eq [IntPtr]::Zero) { throw 'A janela do jogo não apareceu a tempo.' }

    $child = $Process.MainWindowHandle
    $parent = $dex.MainWindowHandle
    [void][AquinoGameWindowNative]::SetParent($child,$parent)

    $WS_CHILD=0x40000000L; $WS_VISIBLE=0x10000000L; $WS_POPUP=0x80000000L
    $WS_CAPTION=0x00C00000L; $WS_THICKFRAME=0x00040000L; $WS_SYSMENU=0x00080000L; $WS_MINIMIZEBOX=0x00020000L; $WS_MAXIMIZEBOX=0x00010000L
    $style=[AquinoGameWindowNative]::GetStyle($child)
    $style = (($style -band (-bnot $WS_POPUP)) -bor $WS_CHILD -bor $WS_VISIBLE -bor $WS_CAPTION -bor $WS_THICKFRAME -bor $WS_SYSMENU -bor $WS_MINIMIZEBOX -bor $WS_MAXIMIZEBOX)
    [AquinoGameWindowNative]::SetStyle($child,$style)

    $r=New-Object AquinoGameWindowNative+RECT
    [void][AquinoGameWindowNative]::GetClientRect($parent,[ref]$r)
    $w=[Math]::Max(520,($r.Right-$r.Left)-($SideMargin*2))
    $h=[Math]::Max(360,($r.Bottom-$r.Top)-$TopMargin-$BottomMargin)
    [void][AquinoGameWindowNative]::MoveWindow($child,$SideMargin,$TopMargin,$w,$h,$true)
    [void][AquinoGameWindowNative]::SetWindowPos($child,[IntPtr]::Zero,$SideMargin,$TopMargin,$w,$h,0x0020 -bor 0x0040)
    [void][AquinoGameWindowNative]::ShowWindow($child,5)
    [pscustomobject]@{Embedded=$true; DexPid=$dex.Id; GamePid=$Process.Id; Width=$w; Height=$h}
}

function Start-AquinoGameWindow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Package,
        [string]$Profile='low_latency',
        [switch]$FlexDisplay,
        [switch]$Fullscreen,
        [switch]$NativeKeyboard,
        [switch]$NativeMouse,
        [switch]$NativeGamepad,
        [switch]$NoAudio,
        [switch]$NoSystemDecorations,
        [switch]$KeepAppOnClose,
        [switch]$ExternalWindow,
        [switch]$EnableTouchMapping,
        [string]$Root=(Get-AquinoRoot)
    )
    $cfg=Get-AquinoGameProfiles -Root $Root; $p=$cfg.profiles.$Profile; if(-not $p){throw "Perfil desconhecido: $Profile"}
    $scrcpy=Resolve-AquinoScrcpy -Root $Root; $codec=Resolve-AquinoVideoCodec -Preferred ([string]$p.video.codec) -ScrcpyPath $scrcpy
    $nd="$($p.display.width)x$($p.display.height)/$($p.display.dpi)"
    $title="Android Dex - $Package"
    $args=@("--new-display=$nd","--start-app=+$Package","--max-fps=$($p.video.fps)","--video-codec=$codec","--video-bit-rate=$($p.video.bitrateMbps)M","--window-title=$title",'--keep-active','--display-ime-policy=local')
    if($FlexDisplay){$args+='--flex-display'}
    if($ExternalWindow -and ($Fullscreen -or [bool]$p.display.fullscreen)){$args+='--fullscreen'}
    if($NativeKeyboard){$args+='--keyboard=uhid'}
    if($NativeMouse){$args+=@('--mouse=uhid','--mouse-bind=++++:++++')}
    if($NativeGamepad){$args+='--gamepad=uhid'}
    if($NoAudio -or -not [bool]$p.audio.enabled){$args+='--no-audio'}
    if($NoSystemDecorations){$args+='--no-vd-system-decorations'}
    if($KeepAppOnClose){$args+='--no-vd-destroy-content'}
    if([bool]$p.video.lowLatency){$args+=@('--video-buffer=0','--audio-buffer=20','--audio-output-buffer=5')}

    $proc=Start-Process -FilePath $scrcpy -WorkingDirectory (Split-Path $scrcpy) -ArgumentList $args -PassThru
    $embedResult=$null
    if(-not $ExternalWindow){ $embedResult=Embed-AquinoGameWindow -Process $proc }

    $mappingProcess=$null
    if($EnableTouchMapping){
        $safe=($Package -replace '[^A-Za-z0-9_.-]','_')
        $profilePath=Join-Path $Root "config\keymaps\$safe.json"
        if(Test-Path $profilePath){
            $mappingProcess=Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Aquino-KeyMapRuntime.ps1'),'-ProfilePath',$profilePath) -PassThru
        }
    }
    [pscustomobject]@{Process=$proc;Arguments=$args;Scrcpy=$scrcpy;Codec=$codec;Profile=$Profile;Package=$Package;Embedded=(-not $ExternalWindow);Embed=$embedResult;MappingProcess=$mappingProcess}
}
Export-ModuleMember -Function *-Aquino*
