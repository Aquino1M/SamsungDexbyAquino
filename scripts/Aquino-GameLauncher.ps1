Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module (Join-Path $PSScriptRoot 'Aquino.Gaming.psm1') -Force
$root = Get-AquinoRoot

$form = New-Object Windows.Forms.Form
$form.Text = 'Aquino Gaming Hub — App Windows'
$form.Size = New-Object Drawing.Size(760,600)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object Drawing.Size(760,600)

$title = New-Object Windows.Forms.Label
$title.Text = 'Aquino Gaming Hub'
$title.Font = New-Object Drawing.Font('Segoe UI',18,[Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object Drawing.Point(22,18)
$form.Controls.Add($title)

$sub = New-Object Windows.Forms.Label
$sub.Text = 'Janelas Android independentes • scrcpy 4 • UHID • alto FPS'
$sub.AutoSize = $true
$sub.Location = New-Object Drawing.Point(25,55)
$form.Controls.Add($sub)

$packageLabel = New-Object Windows.Forms.Label
$packageLabel.Text = 'Aplicativo / pacote Android:'
$packageLabel.AutoSize = $true
$packageLabel.Location = New-Object Drawing.Point(25,95)
$form.Controls.Add($packageLabel)

$packageBox = New-Object Windows.Forms.ComboBox
$packageBox.Location = New-Object Drawing.Point(25,118)
$packageBox.Width = 690
$packageBox.DropDownStyle = 'DropDown'
$form.Controls.Add($packageBox)

$refresh = New-Object Windows.Forms.Button
$refresh.Text = 'Atualizar apps'
$refresh.Location = New-Object Drawing.Point(590,83)
$refresh.Size = New-Object Drawing.Size(125,30)
$form.Controls.Add($refresh)

$profileLabel = New-Object Windows.Forms.Label
$profileLabel.Text = 'Perfil:'
$profileLabel.AutoSize = $true
$profileLabel.Location = New-Object Drawing.Point(25,165)
$form.Controls.Add($profileLabel)

$profileBox = New-Object Windows.Forms.ComboBox
$profileBox.DropDownStyle = 'DropDownList'
$profileBox.Location = New-Object Drawing.Point(80,160)
$profileBox.Width = 210
$profiles = Get-AquinoGameProfiles -Root $root
@($profiles.profiles.PSObject.Properties.Name) | ForEach-Object { [void]$profileBox.Items.Add($_) }
$profileBox.SelectedItem = 'low_latency'
$form.Controls.Add($profileBox)

$flex = New-Object Windows.Forms.CheckBox
$flex.Text = 'Flex display (redimensiona como PC)'
$flex.Checked = $true
$flex.AutoSize = $true
$flex.Location = New-Object Drawing.Point(315,162)
$form.Controls.Add($flex)

$full = New-Object Windows.Forms.CheckBox
$full.Text = 'Tela cheia'
$full.AutoSize = $true
$full.Location = New-Object Drawing.Point(575,162)
$form.Controls.Add($full)

$nativeGroup = New-Object Windows.Forms.GroupBox
$nativeGroup.Text = 'Controles nativos UHID / SDL3'
$nativeGroup.Location = New-Object Drawing.Point(25,205)
$nativeGroup.Size = New-Object Drawing.Size(690,100)
$form.Controls.Add($nativeGroup)

$kbd = New-Object Windows.Forms.CheckBox
$kbd.Text = 'Teclado físico'
$kbd.Checked = $true
$kbd.AutoSize = $true
$kbd.Location = New-Object Drawing.Point(20,30)
$nativeGroup.Controls.Add($kbd)

$mouse = New-Object Windows.Forms.CheckBox
$mouse.Text = 'Mouse físico / relativo'
$mouse.Checked = $true
$mouse.AutoSize = $true
$mouse.Location = New-Object Drawing.Point(175,30)
$nativeGroup.Controls.Add($mouse)

$pad = New-Object Windows.Forms.CheckBox
$pad.Text = 'Gamepad (Xbox / DualSense / SDL)'
$pad.Checked = $true
$pad.AutoSize = $true
$pad.Location = New-Object Drawing.Point(385,30)
$nativeGroup.Controls.Add($pad)

$decor = New-Object Windows.Forms.CheckBox
$decor.Text = 'Sem barras Android no display virtual'
$decor.Checked = $true
$decor.AutoSize = $true
$decor.Location = New-Object Drawing.Point(20,62)
$nativeGroup.Controls.Add($decor)

$keep = New-Object Windows.Forms.CheckBox
$keep.Text = 'Manter app ao fechar janela'
$keep.Checked = $true
$keep.AutoSize = $true
$keep.Location = New-Object Drawing.Point(330,62)
$nativeGroup.Controls.Add($keep)

$open = New-Object Windows.Forms.Button
$open.Text = 'ABRIR JOGO / APP EM JANELA'
$open.Font = New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)
$open.Location = New-Object Drawing.Point(25,325)
$open.Size = New-Object Drawing.Size(330,55)
$form.Controls.Add($open)

$keymap = New-Object Windows.Forms.Button
$keymap.Text = 'EDITOR DE MAPEAMENTO'
$keymap.Font = New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)
$keymap.Location = New-Object Drawing.Point(385,325)
$keymap.Size = New-Object Drawing.Size(330,55)
$form.Controls.Add($keymap)

$status = New-Object Windows.Forms.TextBox
$status.Multiline = $true
$status.ReadOnly = $true
$status.ScrollBars = 'Vertical'
$status.Location = New-Object Drawing.Point(25,400)
$status.Size = New-Object Drawing.Size(690,125)
$form.Controls.Add($status)

function Add-Status([string]$text) { $status.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $text`r`n") }
function Refresh-Apps {
    try {
        $packageBox.Items.Clear()
        $apps = @(Get-AquinoInstalledApps)
        foreach ($a in $apps) { [void]$packageBox.Items.Add($a) }
        if ($apps.Count -gt 0) { $packageBox.SelectedIndex = 0 }
        Add-Status "$($apps.Count) aplicativos do usuário encontrados."
    } catch { Add-Status "ERRO ao listar apps: $($_.Exception.Message)" }
}

$refresh.Add_Click({ Refresh-Apps })
$open.Add_Click({
    try {
        $pkg = [string]$packageBox.Text
        if ([string]::IsNullOrWhiteSpace($pkg)) { throw 'Escolha ou digite o package do jogo.' }
        $result = Start-AquinoGameWindow -Package $pkg -Profile ([string]$profileBox.SelectedItem) -FlexDisplay:$flex.Checked -Fullscreen:$full.Checked -NativeKeyboard:$kbd.Checked -NativeMouse:$mouse.Checked -NativeGamepad:$pad.Checked -NoSystemDecorations:$decor.Checked -KeepAppOnClose:$keep.Checked
        Add-Status "Iniciado: $pkg | perfil=$($result.Profile) | codec=$($result.Codec) | PID=$($result.Process.Id)"
    } catch { Add-Status "ERRO: $($_.Exception.Message)" }
})
$keymap.Add_Click({
    try {
        $pkg = [string]$packageBox.Text
        $args = @('-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Aquino-KeyMapper.ps1'))
        if ($pkg) { $args += @('-Package',$pkg) }
        Start-Process powershell.exe -ArgumentList $args
        Add-Status 'Editor de mapeamento aberto.'
    } catch { Add-Status "ERRO: $($_.Exception.Message)" }
})

Add-Status "scrcpy detectado: $(Get-AquinoScrcpyVersion)"
Add-Status 'Use UHID para jogos com suporte nativo. Use o KeyMapper para jogos touchscreen.'
Refresh-Apps
[void]$form.ShowDialog()
