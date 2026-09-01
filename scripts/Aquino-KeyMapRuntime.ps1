[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ProfilePath)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Import-Module (Join-Path $PSScriptRoot 'Aquino.Gaming.psm1') -Force
if (-not (Test-Path $ProfilePath)) { throw "Keymap não encontrado: $ProfilePath" }
$profile = Get-Content $ProfilePath -Raw | ConvertFrom-Json
$adb = Resolve-AquinoAdb

if (-not ('AquinoInputWin32' -as [type])) {
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class AquinoInputWin32 {
 [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X; public int Y; }
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
 [StructLayout(LayoutKind.Sequential)] public struct XINPUT_GAMEPAD { public ushort wButtons; public byte bLeftTrigger; public byte bRightTrigger; public short sThumbLX; public short sThumbLY; public short sThumbRX; public short sThumbRY; }
 [StructLayout(LayoutKind.Sequential)] public struct XINPUT_STATE { public uint dwPacketNumber; public XINPUT_GAMEPAD Gamepad; }
 [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
 [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
 [DllImport("user32.dll")] public static extern int ShowCursor(bool show);
 [DllImport("xinput1_4.dll", EntryPoint="XInputGetState")] public static extern uint XInputGetState(uint index, out XINPUT_STATE state);
}
'@
}

function Convert-BindingToVk([string]$binding) {
    $b = $binding.ToUpperInvariant()
    $map = @{
        'SPACE'=0x20; 'SHIFT'=0x10; 'CTRL'=0x11; 'ALT'=0x12; 'ENTER'=0x0D; 'TAB'=0x09; 'ESC'=0x1B;
        'UP'=0x26; 'DOWN'=0x28; 'LEFT'=0x25; 'RIGHT'=0x27; 'F1'=0x70; 'F2'=0x71; 'F3'=0x72; 'F4'=0x73;
        'F5'=0x74; 'F6'=0x75; 'F7'=0x76; 'F8'=0x77; 'F9'=0x78; 'F10'=0x79; 'F11'=0x7A; 'F12'=0x7B;
        'LMB'=0x01; 'RMB'=0x02; 'MMB'=0x04
    }
    if ($map.ContainsKey($b)) { return [int]$map[$b] }
    if ($b.Length -eq 1) { return [int][char]$b }
    return -1
}
function Is-KeyDown([string]$binding) {
    if ($binding.ToUpperInvariant().StartsWith('PAD_')) { return $false }
    $vk = Convert-BindingToVk $binding
    if ($vk -lt 0) { return $false }
    return (([AquinoInputWin32]::GetAsyncKeyState($vk) -band 0x8000) -ne 0)
}
function Get-GamepadButtons {
    $set = New-Object 'System.Collections.Generic.HashSet[string]'
    $st = New-Object AquinoInputWin32+XINPUT_STATE
    if ([AquinoInputWin32]::XInputGetState(0,[ref]$st) -ne 0) { return $set }
    $b=[int]$st.Gamepad.wButtons
    $pairs=@{0x1000='PAD_A';0x2000='PAD_B';0x4000='PAD_X';0x8000='PAD_Y';0x0100='PAD_LB';0x0200='PAD_RB';0x0010='PAD_START';0x0020='PAD_BACK';0x0001='PAD_UP';0x0002='PAD_DOWN';0x0004='PAD_LEFT';0x0008='PAD_RIGHT';0x0040='PAD_LS';0x0080='PAD_RS'}
    foreach($k in $pairs.Keys){ if(($b -band [int]$k)-ne 0){ [void]$set.Add($pairs[$k]) } }
    if($st.Gamepad.bLeftTrigger -gt 40){[void]$set.Add('PAD_LT')}; if($st.Gamepad.bRightTrigger -gt 40){[void]$set.Add('PAD_RT')}
    if($st.Gamepad.sThumbLX -gt 12000){[void]$set.Add('PAD_LX_RIGHT')}; if($st.Gamepad.sThumbLX -lt -12000){[void]$set.Add('PAD_LX_LEFT')}
    if($st.Gamepad.sThumbLY -gt 12000){[void]$set.Add('PAD_LY_UP')}; if($st.Gamepad.sThumbLY -lt -12000){[void]$set.Add('PAD_LY_DOWN')}
    return $set
}

$psi = New-Object Diagnostics.ProcessStartInfo
$psi.FileName = $adb
$psi.Arguments = 'shell'
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $true
$shell = New-Object Diagnostics.Process
$shell.StartInfo = $psi
if (-not $shell.Start()) { throw 'Não foi possível abrir adb shell persistente.' }
function Send-Shell([string]$cmd) { if (-not $shell.HasExited) { $shell.StandardInput.WriteLine($cmd); $shell.StandardInput.Flush() } }

$sizeResult = Invoke-AquinoAdb -AdbPath $adb -Arguments @('shell','wm','size') -IgnoreExitCode
$deviceW=1080; $deviceH=1920
if ($sizeResult.Text -match '([0-9]+)x([0-9]+)') { $deviceW=[int]$matches[1]; $deviceH=[int]$matches[2] }
function PxX([double]$x){ [int][Math]::Round([Math]::Max(0,[Math]::Min(1,$x))*($deviceW-1)) }
function PxY([double]$y){ [int][Math]::Round([Math]::Max(0,[Math]::Min(1,$y))*($deviceH-1)) }

$state=@{}; $lastFire=@{}; $fps = @($profile.mappings | Where-Object type -eq 'FPSLook' | Select-Object -First 1)
$fpsLocked=$false; $lastF1=$false
Write-Host "Aquino KeyMapper ativo para $($profile.package). F12 encerra. F1 alterna mouse FPS." -ForegroundColor Green
try {
  while ($true) {
    if (Is-KeyDown 'F12') { break }
    $f1=Is-KeyDown 'F1'; if($f1 -and -not $lastF1 -and $fps.Count -gt 0){$fpsLocked=-not $fpsLocked; [AquinoInputWin32]::ShowCursor(-not $fpsLocked)|Out-Null}; $lastF1=$f1
    $pads=Get-GamepadButtons
    foreach($m in @($profile.mappings)){
      $bind=[string]$m.binding; $down = if($bind.ToUpperInvariant().StartsWith('PAD_')){$pads.Contains($bind.ToUpperInvariant())}else{Is-KeyDown $bind}
      $id=[string]$m.id; $prev=[bool]($state[$id]); $now=[DateTime]::UtcNow
      if($m.type -in @('Tap','GamepadTap','MOBASkill')){
        if($down -and -not $prev){Send-Shell "input tap $(PxX $m.x) $(PxY $m.y)"}
      } elseif($m.type -eq 'RepeatedTap'){
        $interval=if($m.repeatMs){[int]$m.repeatMs}else{80}; $due=(-not $lastFire[$id]) -or (($now-$lastFire[$id]).TotalMilliseconds -ge $interval)
        if($down -and $due){Send-Shell "input tap $(PxX $m.x) $(PxY $m.y)"; $lastFire[$id]=$now}
      } elseif($m.type -eq 'Swipe'){
        if($down -and -not $prev){Send-Shell "input swipe $(PxX $m.x) $(PxY $m.y) $(PxX $m.swipeToX) $(PxY $m.swipeToY) 100"}
      } elseif($m.type -eq 'DPad'){
        $interval=70; $due=(-not $lastFire[$id]) -or (($now-$lastFire[$id]).TotalMilliseconds -ge $interval)
        if($down -and $due){
          $dx=0.0;$dy=0.0;$r=if($m.radius){[double]$m.radius}else{0.12}; $b=$bind.ToUpperInvariant()
          if($b -in @('W','UP','PAD_UP','PAD_LY_UP')){$dy=-$r};if($b -in @('S','DOWN','PAD_DOWN','PAD_LY_DOWN')){$dy=$r};if($b -in @('A','LEFT','PAD_LEFT','PAD_LX_LEFT')){$dx=-$r};if($b -in @('D','RIGHT','PAD_RIGHT','PAD_LX_RIGHT')){$dx=$r}
          Send-Shell "input swipe $(PxX $m.x) $(PxY $m.y) $(PxX ([double]$m.x+$dx)) $(PxY ([double]$m.y+$dy)) 60"; $lastFire[$id]=$now
        }
      } elseif($m.type -eq 'Script'){
        if($down -and -not $prev){ foreach($a in @($m.script)){ if($a.action -eq 'tap'){Send-Shell "input tap $(PxX $a.x) $(PxY $a.y)"}; if($a.action -eq 'swipe'){Send-Shell "input swipe $(PxX $a.x) $(PxY $a.y) $(PxX $a.toX) $(PxY $a.toY) $([int]$a.durationMs)"}; if($a.action -eq 'sleep'){Start-Sleep -Milliseconds ([int]$a.ms)} } }
      }
      $state[$id]=$down
    }
    if($fpsLocked -and $fps.Count -gt 0){
      $proc=Get-Process scrcpy -ErrorAction SilentlyContinue | Where-Object MainWindowHandle -ne 0 | Sort-Object StartTime -Descending | Select-Object -First 1
      if($proc){$r=New-Object AquinoInputWin32+RECT; [AquinoInputWin32]::GetWindowRect($proc.MainWindowHandle,[ref]$r)|Out-Null; $cx=[int](($r.Left+$r.Right)/2);$cy=[int](($r.Top+$r.Bottom)/2);$pt=New-Object AquinoInputWin32+POINT;[AquinoInputWin32]::GetCursorPos([ref]$pt)|Out-Null;$dx=$pt.X-$cx;$dy=$pt.Y-$cy;if([Math]::Abs($dx)+[Math]::Abs($dy)-gt 0){$sens=if($fps[0].sensitivity){[double]$fps[0].sensitivity}else{1.0};$sx=PxX $fps[0].x;$sy=PxY $fps[0].y;$tx=[int]($sx+$dx*$sens);$ty=[int]($sy+$dy*$sens);Send-Shell "input swipe $sx $sy $tx $ty 16"};[AquinoInputWin32]::SetCursorPos($cx,$cy)|Out-Null}
    }
    Start-Sleep -Milliseconds 10
  }
} finally {
  if($fpsLocked){[AquinoInputWin32]::ShowCursor($true)|Out-Null}
  try{$shell.StandardInput.Close()}catch{};try{if(-not $shell.HasExited){$shell.Kill()}}catch{}
}
