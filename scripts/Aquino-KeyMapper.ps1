[CmdletBinding()]
param([string]$Package)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module (Join-Path $PSScriptRoot 'Aquino.Gaming.psm1') -Force
$root = Get-AquinoRoot
$keymapDir = Join-Path $root 'config\keymaps'
New-Item -ItemType Directory -Force -Path $keymapDir | Out-Null

function Get-TargetProcess {
    $candidates = @(Get-Process scrcpy -ErrorAction SilentlyContinue | Where-Object MainWindowHandle -ne 0)
    if ($candidates.Count -eq 0) { $candidates = @(Get-Process Android_Dex -ErrorAction SilentlyContinue | Where-Object MainWindowHandle -ne 0) }
    return ($candidates | Sort-Object StartTime -Descending | Select-Object -First 1)
}

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

function Capture-Target([System.Diagnostics.Process]$proc) {
    $proc.Refresh()
    if ($proc.MainWindowHandle -eq [IntPtr]::Zero) { throw 'A janela do jogo não foi encontrada.' }
    $r = New-Object AquinoCaptureWin32+RECT
    [AquinoCaptureWin32]::GetWindowRect($proc.MainWindowHandle, [ref]$r) | Out-Null
    $w = [Math]::Max(1, $r.Right-$r.Left); $h = [Math]::Max(1, $r.Bottom-$r.Top)
    $bmp = New-Object Drawing.Bitmap($w,$h)
    $g = [Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($r.Left,$r.Top,0,0,(New-Object Drawing.Size($w,$h)))
    $g.Dispose()
    return $bmp
}

$bindings = New-Object System.Collections.ArrayList
$form = New-Object Windows.Forms.Form
$form.Text = 'Aquino KeyMapper — Editor Visual'
$form.Size = New-Object Drawing.Size(1180,760)
$form.StartPosition = 'CenterScreen'
$form.KeyPreview = $true

$left = New-Object Windows.Forms.Panel
$left.Location = New-Object Drawing.Point(10,10)
$left.Size = New-Object Drawing.Size(780,690)
$left.BorderStyle = 'FixedSingle'
$form.Controls.Add($left)

$picture = New-Object Windows.Forms.PictureBox
$picture.Dock = 'Fill'
$picture.SizeMode = 'Zoom'
$picture.BackColor = [Drawing.Color]::FromArgb(20,20,20)
$left.Controls.Add($picture)

$panel = New-Object Windows.Forms.Panel
$panel.Location = New-Object Drawing.Point(805,10)
$panel.Size = New-Object Drawing.Size(345,690)
$form.Controls.Add($panel)

$title = New-Object Windows.Forms.Label
$title.Text = 'Editor de controles'
$title.Font = New-Object Drawing.Font('Segoe UI',15,[Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object Drawing.Point(5,5)
$panel.Controls.Add($title)

$pkgLabel = New-Object Windows.Forms.Label
$pkgLabel.Text = 'Package:'
$pkgLabel.AutoSize = $true
$pkgLabel.Location = New-Object Drawing.Point(5,50)
$panel.Controls.Add($pkgLabel)
$pkg = New-Object Windows.Forms.TextBox
$pkg.Location = New-Object Drawing.Point(5,70)
$pkg.Width = 330
$pkg.Text = if ($Package) { $Package } else { [string](Get-AquinoForegroundPackage) }
$panel.Controls.Add($pkg)

$typeLabel = New-Object Windows.Forms.Label
$typeLabel.Text = 'Tipo do controle:'
$typeLabel.AutoSize = $true
$typeLabel.Location = New-Object Drawing.Point(5,110)
$panel.Controls.Add($typeLabel)
$type = New-Object Windows.Forms.ComboBox
$type.DropDownStyle = 'DropDownList'
$type.Location = New-Object Drawing.Point(5,132)
$type.Width = 160
@('Tap','RepeatedTap','Swipe','DPad','FPSLook','MOBASkill','Zoom','Script','GamepadTap') | ForEach-Object { [void]$type.Items.Add($_) }
$type.SelectedItem = 'Tap'
$panel.Controls.Add($type)

$keyLabel = New-Object Windows.Forms.Label
$keyLabel.Text = 'Tecla / binding:'
$keyLabel.AutoSize = $true
$keyLabel.Location = New-Object Drawing.Point(175,110)
$panel.Controls.Add($keyLabel)
$key = New-Object Windows.Forms.TextBox
$key.Location = New-Object Drawing.Point(175,132)
$key.Width = 160
$key.Text = 'E'
$panel.Controls.Add($key)

$help = New-Object Windows.Forms.Label
$help.Text = "Clique na imagem para adicionar o controle. Bindings:`nE, SPACE, W, A, S, D, LMB, RMB, MMB, F1...`nGamepad: PAD_A, PAD_B, PAD_X, PAD_Y, PAD_LB,`nPAD_RB, PAD_START, PAD_BACK, PAD_UP/DOWN/LEFT/RIGHT."
$help.Location = New-Object Drawing.Point(5,175)
$help.Size = New-Object Drawing.Size(330,90)
$panel.Controls.Add($help)

$list = New-Object Windows.Forms.ListBox
$list.Location = New-Object Drawing.Point(5,275)
$list.Size = New-Object Drawing.Size(330,220)
$panel.Controls.Add($list)

$capture = New-Object Windows.Forms.Button
$capture.Text = 'Capturar janela scrcpy'
$capture.Location = New-Object Drawing.Point(5,510)
$capture.Size = New-Object Drawing.Size(160,38)
$panel.Controls.Add($capture)
$remove = New-Object Windows.Forms.Button
$remove.Text = 'Remover selecionado'
$remove.Location = New-Object Drawing.Point(175,510)
$remove.Size = New-Object Drawing.Size(160,38)
$panel.Controls.Add($remove)

$save = New-Object Windows.Forms.Button
$save.Text = 'SALVAR PERFIL'
$save.Font = New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)
$save.Location = New-Object Drawing.Point(5,560)
$save.Size = New-Object Drawing.Size(160,45)
$panel.Controls.Add($save)
$run = New-Object Windows.Forms.Button
$run.Text = 'ATIVAR MAPEAMENTO'
$run.Font = New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold)
$run.Location = New-Object Drawing.Point(175,560)
$run.Size = New-Object Drawing.Size(160,45)
$panel.Controls.Add($run)

$status = New-Object Windows.Forms.Label
$status.Text = 'Capture a janela do jogo para começar.'
$status.Location = New-Object Drawing.Point(5,620)
$status.Size = New-Object Drawing.Size(330,60)
$panel.Controls.Add($status)

$target = $null
$capturedWidth = 0; $capturedHeight = 0
function Refresh-List {
    $list.Items.Clear()
    foreach ($b in $bindings) { [void]$list.Items.Add("$($b.type) | $($b.binding) | $([Math]::Round($b.x,3)),$([Math]::Round($b.y,3))") }
}
function Do-Capture {
    try {
        $script:target = Get-TargetProcess
        if (-not $script:target) { throw 'Abra primeiro uma janela do jogo/scrcpy.' }
        $img = Capture-Target $script:target
        if ($picture.Image) { $picture.Image.Dispose() }
        $picture.Image = $img
        $script:capturedWidth = $img.Width; $script:capturedHeight = $img.Height
        $status.Text = "Capturado PID $($script:target.Id) — $($img.Width)x$($img.Height). Clique na imagem para mapear."
    } catch { $status.Text = "ERRO: $($_.Exception.Message)" }
}

$picture.Add_MouseClick({
    param($sender,$e)
    if (-not $picture.Image) { return }
    $img = $picture.Image
    $boxW = $picture.ClientSize.Width; $boxH = $picture.ClientSize.Height
    $scale = [Math]::Min($boxW / $img.Width, $boxH / $img.Height)
    $drawW = $img.Width*$scale; $drawH = $img.Height*$scale
    $offX = ($boxW-$drawW)/2; $offY = ($boxH-$drawH)/2
    if ($e.X -lt $offX -or $e.X -gt ($offX+$drawW) -or $e.Y -lt $offY -or $e.Y -gt ($offY+$drawH)) { return }
    $nx = ($e.X-$offX)/$drawW; $ny = ($e.Y-$offY)/$drawH
    $item = [pscustomobject]@{
        id=[guid]::NewGuid().ToString('N'); type=[string]$type.SelectedItem; binding=$key.Text.Trim().ToUpperInvariant();
        x=[double]$nx; y=[double]$ny; repeatMs=80; radius=0.12; sensitivity=1.0;
        swipeToX=[Math]::Min(1.0,$nx+0.15); swipeToY=$ny; script=@()
    }
    [void]$bindings.Add($item)
    Refresh-List
})
$capture.Add_Click({ Do-Capture })
$remove.Add_Click({ if ($list.SelectedIndex -ge 0) { $bindings.RemoveAt($list.SelectedIndex); Refresh-List } })
$save.Add_Click({
    try {
        if ([string]::IsNullOrWhiteSpace($pkg.Text)) { throw 'Informe o package do jogo.' }
        $safe = ($pkg.Text -replace '[^A-Za-z0-9_.-]','_')
        $path = Join-Path $keymapDir "$safe.json"
        $doc = [ordered]@{
            schemaVersion=2; author='Aquino / Aquino1M'; package=$pkg.Text.Trim(); createdAt=(Get-Date).ToString('o');
            referenceWidth=$capturedWidth; referenceHeight=$capturedHeight; mappings=@($bindings)
        }
        $doc | ConvertTo-Json -Depth 12 | Set-Content $path -Encoding UTF8
        $status.Text = "Salvo: $path"
    } catch { $status.Text = "ERRO: $($_.Exception.Message)" }
})
$run.Add_Click({
    try {
        if ([string]::IsNullOrWhiteSpace($pkg.Text)) { throw 'Informe o package do jogo.' }
        $safe = ($pkg.Text -replace '[^A-Za-z0-9_.-]','_')
        $path = Join-Path $keymapDir "$safe.json"
        if (-not (Test-Path $path)) { $save.PerformClick() }
        Start-Process powershell.exe -ArgumentList @('-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Aquino-KeyMapRuntime.ps1'),'-ProfilePath',$path)
        $status.Text = 'Runtime iniciado. F12 encerra; F1 alterna FPS mouse lock quando houver FPSLook.'
    } catch { $status.Text = "ERRO: $($_.Exception.Message)" }
})

Do-Capture
[void]$form.ShowDialog()
