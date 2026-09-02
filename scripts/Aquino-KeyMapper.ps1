[CmdletBinding()]
param(
    [string]$Package,
    [ValidateSet('All','Keyboard','Gamepad')][string]$Mode='All'
)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module (Join-Path $PSScriptRoot 'Aquino.Gaming.psm1') -Force
$root = Get-AquinoRoot
$keymapDir = Join-Path $root 'config\keymaps'
New-Item -ItemType Directory -Force -Path $keymapDir | Out-Null

if (-not ('AquinoCaptureWin32' -as [type])) {
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class AquinoCaptureWin32 {
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
}
'@
}
if (-not ('AquinoGamepadPoll' -as [type])) {
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class AquinoGamepadPoll {
 [StructLayout(LayoutKind.Sequential)] public struct GP { public ushort Buttons; public byte LT; public byte RT; public short LX; public short LY; public short RX; public short RY; }
 [StructLayout(LayoutKind.Sequential)] public struct State { public uint Packet; public GP Gamepad; }
 [DllImport("xinput1_4.dll", EntryPoint="XInputGetState")] static extern uint X14(uint i, out State s);
 [DllImport("xinput9_1_0.dll", EntryPoint="XInputGetState")] static extern uint X91(uint i, out State s);
 static bool Read(out State s) { try { return X14(0,out s)==0; } catch { try { return X91(0,out s)==0; } catch { s=new State(); return false; } } }
 public static string Pressed() {
   State s; if(!Read(out s)) return ""; ushort b=s.Gamepad.Buttons;
   if((b&0x1000)!=0)return "PAD_A"; if((b&0x2000)!=0)return "PAD_B"; if((b&0x4000)!=0)return "PAD_X"; if((b&0x8000)!=0)return "PAD_Y";
   if((b&0x0100)!=0)return "PAD_LB"; if((b&0x0200)!=0)return "PAD_RB"; if((b&0x0010)!=0)return "PAD_START"; if((b&0x0020)!=0)return "PAD_BACK";
   if((b&0x0001)!=0)return "PAD_UP"; if((b&0x0002)!=0)return "PAD_DOWN"; if((b&0x0004)!=0)return "PAD_LEFT"; if((b&0x0008)!=0)return "PAD_RIGHT";
   if(s.Gamepad.LT>50)return "PAD_LT"; if(s.Gamepad.RT>50)return "PAD_RT";
   if(s.Gamepad.LX>14000)return "PAD_LX_RIGHT"; if(s.Gamepad.LX<-14000)return "PAD_LX_LEFT"; if(s.Gamepad.LY>14000)return "PAD_LY_UP"; if(s.Gamepad.LY<-14000)return "PAD_LY_DOWN";
   if(s.Gamepad.RX>14000)return "PAD_RX_RIGHT"; if(s.Gamepad.RX<-14000)return "PAD_RX_LEFT"; if(s.Gamepad.RY>14000)return "PAD_RY_UP"; if(s.Gamepad.RY<-14000)return "PAD_RY_DOWN";
   return "";
 }
}
'@
}

function Get-TargetProcess {
    $candidates = @(Get-Process scrcpy -ErrorAction SilentlyContinue | Where-Object MainWindowHandle -ne 0)
    if ($candidates.Count -eq 0) { $candidates = @(Get-Process Android_Dex -ErrorAction SilentlyContinue | Where-Object MainWindowHandle -ne 0) }
    return ($candidates | Sort-Object StartTime -Descending | Select-Object -First 1)
}
function Capture-Target([System.Diagnostics.Process]$proc) {
    $proc.Refresh(); if ($proc.MainWindowHandle -eq [IntPtr]::Zero) { throw 'A janela do jogo não foi encontrada.' }
    $r = New-Object AquinoCaptureWin32+RECT; [AquinoCaptureWin32]::GetWindowRect($proc.MainWindowHandle, [ref]$r) | Out-Null
    $w = [Math]::Max(1,$r.Right-$r.Left); $h=[Math]::Max(1,$r.Bottom-$r.Top)
    $bmp=New-Object Drawing.Bitmap($w,$h); $g=[Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($r.Left,$r.Top,0,0,(New-Object Drawing.Size($w,$h))); $g.Dispose(); return $bmp
}

$bindings = New-Object System.Collections.ArrayList
$form = New-Object Windows.Forms.Form
$form.Text = 'Aquino KeyMapper — Teclado e Gamepad'
$form.Size = New-Object Drawing.Size(1240,800)
$form.MinimumSize = New-Object Drawing.Size(1100,700)
$form.StartPosition = 'CenterScreen'
$form.KeyPreview = $true

$left=New-Object Windows.Forms.Panel; $left.Location=New-Object Drawing.Point(10,10); $left.Size=New-Object Drawing.Size(820,730); $left.BorderStyle='FixedSingle'; $form.Controls.Add($left)
$picture=New-Object Windows.Forms.PictureBox; $picture.Dock='Fill'; $picture.SizeMode='Zoom'; $picture.BackColor=[Drawing.Color]::FromArgb(20,20,20); $left.Controls.Add($picture)
$panel=New-Object Windows.Forms.Panel; $panel.Location=New-Object Drawing.Point(845,10); $panel.Size=New-Object Drawing.Size(370,730); $form.Controls.Add($panel)

$title=New-Object Windows.Forms.Label; $title.Text='Editor estilo BlueStacks'; $title.Font=New-Object Drawing.Font('Segoe UI',15,[Drawing.FontStyle]::Bold); $title.AutoSize=$true; $title.Location=New-Object Drawing.Point(5,5); $panel.Controls.Add($title)
$sub=New-Object Windows.Forms.Label; $sub.Text='Clique no jogo e associe teclas ou botões do controle.'; $sub.Size=New-Object Drawing.Size(350,38); $sub.Location=New-Object Drawing.Point(5,37); $panel.Controls.Add($sub)
$pkgLabel=New-Object Windows.Forms.Label; $pkgLabel.Text='Package do jogo:'; $pkgLabel.AutoSize=$true; $pkgLabel.Location=New-Object Drawing.Point(5,80); $panel.Controls.Add($pkgLabel)
$pkg=New-Object Windows.Forms.TextBox; $pkg.Location=New-Object Drawing.Point(5,100); $pkg.Width=350; $pkg.Text = $(if ($Package) { $Package } else { [string](Get-AquinoForegroundPackage) }); $panel.Controls.Add($pkg)

$typeLabel=New-Object Windows.Forms.Label; $typeLabel.Text='Ação:'; $typeLabel.AutoSize=$true; $typeLabel.Location=New-Object Drawing.Point(5,140); $panel.Controls.Add($typeLabel)
$type=New-Object Windows.Forms.ComboBox; $type.DropDownStyle='DropDownList'; $type.Location=New-Object Drawing.Point(5,160); $type.Width=155; @('Tap','GamepadTap','RepeatedTap','Swipe','DPad','FPSLook')|%{[void]$type.Items.Add($_)}; $type.SelectedItem = $(if ($Mode -eq 'Gamepad') { 'GamepadTap' } else { 'Tap' }); $panel.Controls.Add($type)
$bindLabel=New-Object Windows.Forms.Label; $bindLabel.Text='Tecla / botão:'; $bindLabel.AutoSize=$true; $bindLabel.Location=New-Object Drawing.Point(175,140); $panel.Controls.Add($bindLabel)
$bindingCombo=New-Object Windows.Forms.ComboBox; $bindingCombo.Location=New-Object Drawing.Point(175,160); $bindingCombo.Width=180; $bindingCombo.DropDownStyle='DropDown';
$padBindings=@('PAD_A','PAD_B','PAD_X','PAD_Y','PAD_LB','PAD_RB','PAD_LT','PAD_RT','PAD_START','PAD_BACK','PAD_UP','PAD_DOWN','PAD_LEFT','PAD_RIGHT','PAD_LX_LEFT','PAD_LX_RIGHT','PAD_LY_UP','PAD_LY_DOWN','PAD_RX_LEFT','PAD_RX_RIGHT','PAD_RY_UP','PAD_RY_DOWN')
$keyBindings=@('W','A','S','D','SPACE','SHIFT','CTRL','ALT','ENTER','TAB','ESC','E','Q','R','F','1','2','3','4','LMB','RMB','MMB','F1','F2','F3','F4')
$initial = $(if ($Mode -eq 'Keyboard') { $keyBindings } elseif ($Mode -eq 'Gamepad') { $padBindings } else { $keyBindings + $padBindings }); $initial|%{[void]$bindingCombo.Items.Add($_)}; $bindingCombo.Text = $(if ($Mode -eq 'Gamepad') { 'PAD_A' } else { 'E' }); $panel.Controls.Add($bindingCombo)

$detect=New-Object Windows.Forms.Button; $detect.Text='Detectar botão do gamepad'; $detect.Location=New-Object Drawing.Point(5,200); $detect.Size=New-Object Drawing.Size(170,34); $panel.Controls.Add($detect)
$leftStick=New-Object Windows.Forms.Button; $leftStick.Text='Adicionar analógico ESQ'; $leftStick.Location=New-Object Drawing.Point(185,200); $leftStick.Size=New-Object Drawing.Size(170,34); $panel.Controls.Add($leftStick)
$rightStick=New-Object Windows.Forms.Button; $rightStick.Text='Adicionar analógico DIR'; $rightStick.Location=New-Object Drawing.Point(185,240); $rightStick.Size=New-Object Drawing.Size(170,34); $panel.Controls.Add($rightStick)
$capture=New-Object Windows.Forms.Button; $capture.Text='Capturar jogo no Dex'; $capture.Location=New-Object Drawing.Point(5,240); $capture.Size=New-Object Drawing.Size(170,34); $panel.Controls.Add($capture)

$help=New-Object Windows.Forms.Label; $help.Text="1. Abra o jogo dentro do Android Dex.`n2. Capture a janela.`n3. Escolha tecla/botão e clique no ponto da tela.`n4. Salve e ative o perfil.`nAnalógicos: clique no centro do joystick virtual e use os botões automáticos."; $help.Location=New-Object Drawing.Point(5,285); $help.Size=New-Object Drawing.Size(350,110); $panel.Controls.Add($help)
$list=New-Object Windows.Forms.ListBox; $list.Location=New-Object Drawing.Point(5,400); $list.Size=New-Object Drawing.Size(350,180); $panel.Controls.Add($list)
$remove=New-Object Windows.Forms.Button; $remove.Text='Remover'; $remove.Location=New-Object Drawing.Point(5,590); $remove.Size=New-Object Drawing.Size(105,34); $panel.Controls.Add($remove)
$clear=New-Object Windows.Forms.Button; $clear.Text='Limpar tudo'; $clear.Location=New-Object Drawing.Point(125,590); $clear.Size=New-Object Drawing.Size(105,34); $panel.Controls.Add($clear)
$load=New-Object Windows.Forms.Button; $load.Text='Carregar'; $load.Location=New-Object Drawing.Point(245,590); $load.Size=New-Object Drawing.Size(110,34); $panel.Controls.Add($load)
$save=New-Object Windows.Forms.Button; $save.Text='SALVAR PERFIL'; $save.Font=New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold); $save.Location=New-Object Drawing.Point(5,635); $save.Size=New-Object Drawing.Size(170,42); $panel.Controls.Add($save)
$run=New-Object Windows.Forms.Button; $run.Text='ATIVAR MAPEAMENTO'; $run.Font=New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold); $run.Location=New-Object Drawing.Point(185,635); $run.Size=New-Object Drawing.Size(170,42); $panel.Controls.Add($run)
$status=New-Object Windows.Forms.Label; $status.Text='Capture o jogo para começar.'; $status.Location=New-Object Drawing.Point(5,685); $status.Size=New-Object Drawing.Size(350,40); $panel.Controls.Add($status)

$script:target=$null; $script:capturedWidth=0; $script:capturedHeight=0; $script:pendingStick=$null; $script:detecting=$false
function Refresh-List { $list.Items.Clear(); foreach($b in $bindings){[void]$list.Items.Add("$($b.type) | $($b.binding) | $([Math]::Round($b.x,3)),$([Math]::Round($b.y,3))")}; $picture.Invalidate() }
function Add-Map([string]$mapType,[string]$bind,[double]$x,[double]$y,[double]$radius=0.12){ [void]$bindings.Add([pscustomobject]@{id=[guid]::NewGuid().ToString('N');type=$mapType;binding=$bind;x=$x;y=$y;repeatMs=70;radius=$radius;sensitivity=1.0;swipeToX=[Math]::Min(1.0,$x+0.15);swipeToY=$y;script=@()}) }
function Do-Capture { try{$script:target=Get-TargetProcess;if (-not $script:target){throw 'Abra primeiro o jogo no Android Dex.'};$img=Capture-Target $script:target;if($picture.Image){$picture.Image.Dispose()};$picture.Image=$img;$script:capturedWidth=$img.Width;$script:capturedHeight=$img.Height;$status.Text="Jogo capturado ($($img.Width)x$($img.Height)). Clique na imagem para mapear.";$picture.Invalidate()}catch{$status.Text="ERRO: $($_.Exception.Message)"} }
function Get-MapPath { if([string]::IsNullOrWhiteSpace($pkg.Text)){throw 'Informe o package do jogo.'};$safe=($pkg.Text -replace '[^A-Za-z0-9_.-]','_');Join-Path $keymapDir "$safe.json" }

$picture.Add_Paint({param($sender,$e); if(-not $picture.Image){return};$img=$picture.Image;$boxW=$picture.ClientSize.Width;$boxH=$picture.ClientSize.Height;$scale=[Math]::Min($boxW/$img.Width,$boxH/$img.Height);$drawW=$img.Width*$scale;$drawH=$img.Height*$scale;$offX=($boxW-$drawW)/2;$offY=($boxH-$drawH)/2;$font=New-Object Drawing.Font('Segoe UI',8,[Drawing.FontStyle]::Bold);foreach($b in $bindings){$x=[single]($offX+$b.x*$drawW);$y=[single]($offY+$b.y*$drawH);$rect=New-Object Drawing.RectangleF(($x-18),($y-18),36,36);$e.Graphics.FillEllipse([Drawing.Brushes]::Black,$rect);$e.Graphics.DrawEllipse([Drawing.Pens]::White,$rect);$label=[string]$b.binding;if($label.StartsWith('PAD_')){$label=$label.Substring(4)};$sz=$e.Graphics.MeasureString($label,$font);$e.Graphics.DrawString($label,$font,[Drawing.Brushes]::White,($x-$sz.Width/2),($y-$sz.Height/2))};$font.Dispose()})
$picture.Add_MouseClick({
    param($sender,$e)
    if (-not $picture.Image) { return }
    $img=$picture.Image
    $boxW=$picture.ClientSize.Width; $boxH=$picture.ClientSize.Height
    $scale=[Math]::Min($boxW/$img.Width,$boxH/$img.Height)
    $drawW=$img.Width*$scale; $drawH=$img.Height*$scale
    $offX=($boxW-$drawW)/2; $offY=($boxH-$drawH)/2
    if ($e.X -lt $offX -or $e.X -gt ($offX+$drawW) -or $e.Y -lt $offY -or $e.Y -gt ($offY+$drawH)) { return }
    $nx=($e.X-$offX)/$drawW; $ny=($e.Y-$offY)/$drawH
    if ($script:pendingStick -eq 'LEFT') {
        foreach($b in @('PAD_LY_UP','PAD_LY_DOWN','PAD_LX_LEFT','PAD_LX_RIGHT')) { Add-Map 'DPad' $b $nx $ny }
        $script:pendingStick=$null; $status.Text='Analógico esquerdo adicionado.'
    } elseif ($script:pendingStick -eq 'RIGHT') {
        foreach($b in @('PAD_RY_UP','PAD_RY_DOWN','PAD_RX_LEFT','PAD_RX_RIGHT')) { Add-Map 'DPad' $b $nx $ny 0.10 }
        $script:pendingStick=$null; $status.Text='Analógico direito adicionado.'
    } else {
        Add-Map ([string]$type.SelectedItem) ($bindingCombo.Text.Trim().ToUpperInvariant()) $nx $ny
    }
    Refresh-List
})
$capture.Add_Click({Do-Capture});$leftStick.Add_Click({$script:pendingStick='LEFT';$status.Text='Clique no centro do joystick esquerdo do jogo.'});$rightStick.Add_Click({$script:pendingStick='RIGHT';$status.Text='Clique no centro da área de câmera/joystick direito.'})
$detect.Add_Click({$script:detecting=$true;$status.Text='Pressione um botão ou mova um analógico no controle...'})
$timer=New-Object Windows.Forms.Timer;$timer.Interval=120;$timer.Add_Tick({if($script:detecting){$p=[AquinoGamepadPoll]::Pressed();if($p){$bindingCombo.Text=$p;$script:detecting=$false;$status.Text="Detectado: $p"}}});$timer.Start()
$remove.Add_Click({if ($list.SelectedIndex -ge 0){$bindings.RemoveAt($list.SelectedIndex);Refresh-List}});$clear.Add_Click({$bindings.Clear();Refresh-List})
$save.Add_Click({try{$path=Get-MapPath;$doc=[ordered]@{schemaVersion=3;author='Aquino / Aquino1M';package=$pkg.Text.Trim();createdAt=(Get-Date).ToString('o');referenceWidth=$script:capturedWidth;referenceHeight=$script:capturedHeight;mappings=@($bindings)};$doc|ConvertTo-Json -Depth 12|Set-Content $path -Encoding UTF8;$status.Text="Perfil salvo: $path"}catch{$status.Text="ERRO: $($_.Exception.Message)"}})
$load.Add_Click({try{$path=Get-MapPath;if (-not (Test-Path $path)){throw 'Perfil ainda não existe.'};$doc=Get-Content $path -Raw|ConvertFrom-Json;$bindings.Clear();foreach($m in @($doc.mappings)){[void]$bindings.Add($m)};$script:capturedWidth=[int]$doc.referenceWidth;$script:capturedHeight=[int]$doc.referenceHeight;Refresh-List;$status.Text="Perfil carregado: $path"}catch{$status.Text="ERRO: $($_.Exception.Message)"}})
$run.Add_Click({try{$path=Get-MapPath;if (-not (Test-Path $path)){$save.PerformClick()};Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Aquino-KeyMapRuntime.ps1'),'-ProfilePath',$path);$status.Text='Mapeamento ativo. F12 encerra o runtime.'}catch{$status.Text="ERRO: $($_.Exception.Message)"}})
$form.Add_FormClosed({$timer.Stop();if($picture.Image){$picture.Image.Dispose()}})
Do-Capture
[void]$form.ShowDialog()
