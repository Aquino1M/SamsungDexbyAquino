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
function Start-AquinoGameWindow {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Package,[string]$Profile='low_latency',[switch]$FlexDisplay,[switch]$Fullscreen,[switch]$NativeKeyboard,[switch]$NativeMouse,[switch]$NativeGamepad,[switch]$NoAudio,[switch]$NoSystemDecorations,[switch]$KeepAppOnClose,[string]$Root=(Get-AquinoRoot))
    $cfg=Get-AquinoGameProfiles -Root $Root; $p=$cfg.profiles.$Profile; if(-not $p){throw "Perfil desconhecido: $Profile"}
    $scrcpy=Resolve-AquinoScrcpy -Root $Root; $codec=Resolve-AquinoVideoCodec -Preferred ([string]$p.video.codec) -ScrcpyPath $scrcpy
    $nd="$($p.display.width)x$($p.display.height)/$($p.display.dpi)"; $args=@("--new-display=$nd","--start-app=+$Package","--max-fps=$($p.video.fps)","--video-codec=$codec","--video-bit-rate=$($p.video.bitrateMbps)M","--window-title=Aquino Game - $Package",'--keep-active','--display-ime-policy=local')
    if($FlexDisplay){$args+='--flex-display'};if($Fullscreen -or [bool]$p.display.fullscreen){$args+='--fullscreen'};if($NativeKeyboard){$args+='--keyboard=uhid'};if($NativeMouse){$args+=@('--mouse=uhid','--mouse-bind=++++:++++')};if($NativeGamepad){$args+='--gamepad=uhid'};if($NoAudio -or -not [bool]$p.audio.enabled){$args+='--no-audio'};if($NoSystemDecorations){$args+='--no-vd-system-decorations'};if($KeepAppOnClose){$args+='--no-vd-destroy-content'}
    if([bool]$p.video.lowLatency){$args+=@('--video-buffer=0','--audio-buffer=20','--audio-output-buffer=5')}
    $proc=Start-Process -FilePath $scrcpy -WorkingDirectory (Split-Path $scrcpy) -ArgumentList $args -PassThru
    [pscustomobject]@{Process=$proc;Arguments=$args;Scrcpy=$scrcpy;Codec=$codec;Profile=$Profile;Package=$Package}
}
Export-ModuleMember -Function *-Aquino*
