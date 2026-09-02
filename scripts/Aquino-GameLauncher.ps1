Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module (Join-Path $PSScriptRoot 'Aquino.Gaming.psm1') -Force
$root = Get-AquinoRoot

$form = New-Object Windows.Forms.Form
$form.Text = 'Aquino Gaming — Integrado ao Android Dex'
$form.Size = New-Object Drawing.Size(790,650)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object Drawing.Size(790,650)

$title = New-Object Windows.Forms.Label
$title.Text = 'Jogos e Controles Aquino'
$title.Font = New-Object Drawing.Font('Segoe UI',18,[Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object Drawing.Point(22,18)
$form.Controls.Add($title)

$sub = New-Object Windows.Forms.Label
$sub.Text = 'Janela integrada ao Dex • Gamepad UHID • KeyMapper tipo BlueStacks • alto FPS'
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
$packageBox.Width = 720
$packageBox.DropDownStyle = 'DropDown'
$form.Controls.Add($packageBox)

$refresh = New-Object Windows.Forms.Button
$refresh.Text = 'Atualizar apps'
$refresh.Location = New-Object Drawing.Point(620,83)
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
$flex.Text = 'Flex display'
$flex.Checked = $true
$flex.AutoSize = $true
$flex.Location = New-Object Drawing.Point(315,162)
$form.Controls.Add($flex)

$external = New-Object Windows.Forms.CheckBox
$external.Text = 'Abrir fora do Dex'
$external.Checked = $false
$external.AutoSize = $true
$external.Location = New-Object Drawing.Point(440,162)
$form.Controls.Add($external)

$full = New-Object Windows.Forms.CheckBox
$full.Text = 'Tela cheia (modo externo)'
$full.AutoSize = $true
$full.Location = New-Object Drawing.Point(575,162)
$form.Controls.Add($full)

$nativeGroup = New-Object Windows.Forms.GroupBox
$nativeGroup.Text = 'Controles e desempenho'
$nativeGroup.Location = New-Object Drawing.Point(25,205)
$nativeGroup.Size = New-Object Drawing.Size(720,125)
$form.Controls.Add($nativeGroup)

$kbd = New-Object Windows.Forms.CheckBox
$kbd.Text = 'Teclado UHID'
$kbd.Checked = $true
$kbd.AutoSize = $true
$kbd.Location = New-Object Drawing.Point(20,30)
$nativeGroup.Controls.Add($kbd)

$mouse = New-Object Windows.Forms.CheckBox
$mouse.Text = 'Mouse UHID / relativo'
$mouse.Checked = $true
$mouse.AutoSize = $true
$mouse.Location = New-Object Drawing.Point(175,30)
$nativeGroup.Controls.Add($mouse)

$pad = New-Object Windows.Forms.CheckBox
$pad.Text = 'Gamepad Xbox / DualSense / SDL'
$pad.Checked = $true
$pad.AutoSize = $true
$pad.Location = New-Object Drawing.Point(385,30)
$nativeGroup.Controls.Add($pad)

$mapping = New-Object Windows.Forms.CheckBox
$mapping.Text = 'Ativar perfil de mapeamento salvo para o jogo'
$mapping.Checked = $true
$mapping.AutoSize = $true
$mapping.Location = New-Object Drawing.Point(20,62)
$nativeGroup.Controls.Add($mapping)

$decor = New-Object Windows.Forms.CheckBox
$decor.Text = 'Sem barras Android no display virtual'
$decor.Checked = $true
$decor.AutoSize = $true
$decor.Location = New-Object Drawing.Point(20,90)
$nativeGroup.Controls.Add($decor)

$keep = New-Object Windows.Forms.CheckBox
$keep.Text = 'Manter app ao fechar janela'
$keep.Checked = $true
$keep.AutoSize = $true
$keep.Location = New-Object Drawing.Point(330,90)
$nativeGroup.Controls.Add($keep)

$open = New-Object Windows.Forms.Button
$open.Text = 'ABRIR DENTRO DO ANDROID DEX'
$open.Font = New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)
$open.Location = New-Object Drawing.Point(25,350)
$open.Size = New-Object Drawing.Size(350,58)
$form.Controls.Add($open)

$keymap = New-Object Windows.Forms.Button
$keymap.Text = 'EDITAR TECLAS / GAMEPAD'
$keymap.Font = New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)
$keymap.Location = New-Object Drawing.Point(395,350)
$keymap.Size = New-Object Drawing.Size(350,58)
$form.Controls.Add($keymap)

$status = New-Object Windows.Forms.TextBox
$status.Multiline = $true
$status.ReadOnly = $true
$status.ScrollBars = 'Vertical'
$status.Location = New-Object Drawing.Point(25,430)
$status.Size = New-Object Drawing.Size(720,145)
$form.Controls.Add($status)

function Add-Status([string]$text) { $status.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $text`r`n") }
function Refresh-Apps {
    try {
        $packageBox.Items.Clear(); $apps = @(Get-AquinoInstalledApps)
        foreach ($a in $apps) { [void]$packageBox.Items.Add($a) }
        if ($apps.Count -gt 0) { $packageBox.SelectedIndex = 0 }
        Add-Status "$($apps.Count) aplicativos do usuário encontrados."
    } catch { Add-Status "ERRO ao listar apps: $($_.Exception.Message)" }
}

$refresh.Add_Click({ Refresh-Apps })
$external.Add_CheckedChanged({ $open.Text = if($external.Checked){'ABRIR JOGO EM JANELA EXTERNA'}else{'ABRIR DENTRO DO ANDROID DEX'} })
$open.Add_Click({
    try {
        $pkg = [string]$packageBox.Text
        if ([string]::IsNullOrWhiteSpace($pkg)) { throw 'Escolha ou digite o package do jogo.' }
        $result = Start-AquinoGameWindow -Package $pkg -Profile ([string]$profileBox.SelectedItem) -FlexDisplay:$flex.Checked -Fullscreen:$full.Checked -NativeKeyboard:$kbd.Checked -NativeMouse:$mouse.Checked -NativeGamepad:$pad.Checked -NoSystemDecorations:$decor.Checked -KeepAppOnClose:$keep.Checked -ExternalWindow:$external.Checked -EnableTouchMapping:$mapping.Checked
        $where = if($result.Embedded){'integrado ao Android Dex'}else{'janela externa'}
        Add-Status "Iniciado ${where}: $pkg | perfil=$($result.Profile) | codec=$($result.Codec) | PID=$($result.Process.Id)"
    } catch { Add-Status "ERRO: $($_.Exception.Message)" }
})
$keymap.Add_Click({
    try {
        $pkg = [string]$packageBox.Text
        $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Aquino-KeyMapper.ps1'),'-Mode','Gamepad')
        if ($pkg) { $args += @('-Package',$pkg) }
        Start-Process powershell.exe -ArgumentList $args
        Add-Status 'Editor tipo BlueStacks aberto para teclado/gamepad.'
    } catch { Add-Status "ERRO: $($_.Exception.Message)" }
})

Add-Status "scrcpy detectado: $(Get-AquinoScrcpyVersion)"
Add-Status 'Modo padrão: o jogo é reparentado para dentro da janela principal do Android Dex.'
Add-Status 'Para jogos touchscreen, use Editar Teclas / Gamepad e salve um perfil por package.'
Refresh-Apps
[void]$form.ShowDialog()
