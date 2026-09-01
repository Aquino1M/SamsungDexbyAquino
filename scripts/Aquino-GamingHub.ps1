Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module (Join-Path $PSScriptRoot 'AndroidDex.Aquino.psm1') -Force
$form=New-Object Windows.Forms.Form
$form.Text='Aquino Gaming Hub'
$form.Size=New-Object Drawing.Size(520,390)
$form.StartPosition='CenterScreen'
$t=New-Object Windows.Forms.Label;$t.Text='Aquino Gaming Hub';$t.Font=New-Object Drawing.Font('Segoe UI',20,[Drawing.FontStyle]::Bold);$t.AutoSize=$true;$t.Location=New-Object Drawing.Point(25,20);$form.Controls.Add($t)
$s=New-Object Windows.Forms.Label;$s.Text='Jogos Android no PC | KeyMapper | UHID | Gamepad | 165 FPS';$s.AutoSize=$true;$s.Location=New-Object Drawing.Point(28,65);$form.Controls.Add($s)
$buttons=@(
 @('Abrir jogo em janela independente','Aquino-GameLauncher.ps1'),
 @('Editor visual de teclado / mouse','Aquino-KeyMapper.ps1'),
 @('Diagnostico do scrcpy / encoders','Aquino-ScrcpyProbe.ps1'),
 @('Control Center principal','Aquino-ControlCenter.ps1')
)
$y=110
foreach($b in $buttons){$btn=New-Object Windows.Forms.Button;$btn.Text=$b[0];$btn.Location=New-Object Drawing.Point(30,$y);$btn.Size=New-Object Drawing.Size(445,48);$script=$b[1];$btn.Add_Click({param($sender,$e);$file=$sender.Tag;Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot $file))});$btn.Tag=$script;$form.Controls.Add($btn);$y+=58}
$c=New-Object Windows.Forms.Label;$c.Text='Criado por Aquino | github.com/Aquino1M';$c.AutoSize=$true;$c.Location=New-Object Drawing.Point(30,345);$form.Controls.Add($c)
[void]$form.ShowDialog()
