Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module (Join-Path $PSScriptRoot 'AndroidDex.Aquino.psm1') -Force
$root = Get-AquinoRoot

$form = New-Object Windows.Forms.Form
$form.Text = 'Android Dex by Aquino — Control Center'
$form.Size = New-Object Drawing.Size(620,455)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object Drawing.Size(620,455)

$title = New-Object Windows.Forms.Label
$title.Text = 'Android Dex by Aquino'
$title.Font = New-Object Drawing.Font('Segoe UI',18,[Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object Drawing.Point(24,20)
$form.Controls.Add($title)

$credit = New-Object Windows.Forms.Label
$credit.Text = 'Criado por Aquino • github.com/Aquino1M'
$credit.AutoSize = $true
$credit.Location = New-Object Drawing.Point(27,58)
$form.Controls.Add($credit)

$profileLabel = New-Object Windows.Forms.Label
$profileLabel.Text = 'Perfil:'
$profileLabel.AutoSize = $true
$profileLabel.Location = New-Object Drawing.Point(28,105)
$form.Controls.Add($profileLabel)

$profileBox = New-Object Windows.Forms.ComboBox
$profileBox.DropDownStyle = 'DropDownList'
$profileBox.Location = New-Object Drawing.Point(90,100)
$profileBox.Width = 240
$profiles = Get-AquinoGameProfiles -Root $root
@($profiles.profiles.PSObject.Properties.Name) | ForEach-Object { [void]$profileBox.Items.Add($_) }
$profileBox.SelectedItem = 'default'
$form.Controls.Add($profileBox)

$fullscreen = New-Object Windows.Forms.CheckBox
$fullscreen.Text = 'Tela cheia / jogo'
$fullscreen.AutoSize = $true
$fullscreen.Location = New-Object Drawing.Point(355,103)
$form.Controls.Add($fullscreen)

$status = New-Object Windows.Forms.TextBox
$status.Multiline = $true
$status.ReadOnly = $true
$status.ScrollBars = 'Vertical'
$status.Location = New-Object Drawing.Point(28,285)
$status.Size = New-Object Drawing.Size(545,90)
$form.Controls.Add($status)

function Add-Status([string]$text) {
    $status.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $text`r`n")
}

$start = New-Object Windows.Forms.Button
$start.Text = 'Iniciar Android Dex'
$start.Location = New-Object Drawing.Point(28,145)
$start.Size = New-Object Drawing.Size(165,48)
$start.Add_Click({
    try {
        $args = @('-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Start-AndroidDex.ps1'),'-Profile',[string]$profileBox.SelectedItem)
        if ($fullscreen.Checked) { $args += '-Fullscreen' }
        Start-Process powershell.exe -ArgumentList $args -WindowStyle Hidden
        Add-Status 'Inicialização enviada ao Aquino Launcher.'
    } catch { Add-Status "ERRO: $($_.Exception.Message)" }
})
$form.Controls.Add($start)

$repair = New-Object Windows.Forms.Button
$repair.Text = 'Reparar ADB'
$repair.Location = New-Object Drawing.Point(205,145)
$repair.Size = New-Object Drawing.Size(115,48)
$repair.Add_Click({
    try {
        $adb = Resolve-AquinoAdb -Root $root
        $ok = Repair-AquinoAdb -AdbPath $adb -Retries 3
        Add-Status "ADB reparado: $ok"
    } catch { Add-Status "ERRO: $($_.Exception.Message)" }
})
$form.Controls.Add($repair)

$diag = New-Object Windows.Forms.Button
$diag.Text = 'Diagnóstico'
$diag.Location = New-Object Drawing.Point(332,145)
$diag.Size = New-Object Drawing.Size(115,48)
$diag.Add_Click({
    try {
        $checks = @(Get-AquinoHealth -Root $root)
        $ok = @($checks | Where-Object Ok).Count
        Add-Status "Saúde: $ok/$($checks.Count) verificações OK."
        Start-Process powershell.exe -ArgumentList @('-NoExit','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Diagnostics.ps1'))
    } catch { Add-Status "ERRO: $($_.Exception.Message)" }
})
$form.Controls.Add($diag)

$fullNow = New-Object Windows.Forms.Button
$fullNow.Text = 'Fullscreen agora'
$fullNow.Location = New-Object Drawing.Point(459,145)
$fullNow.Size = New-Object Drawing.Size(115,48)
$fullNow.Add_Click({
    try {
        $p = Get-Process Android_Dex -ErrorAction Stop | Where-Object MainWindowHandle -ne 0 | Select-Object -First 1
        Set-AquinoBorderlessFullscreen -Process $p
        Add-Status 'Fullscreen aplicado à janela Android_Dex.'
    } catch { Add-Status "ERRO: $($_.Exception.Message)" }
})
$form.Controls.Add($fullNow)

$gaming = New-Object Windows.Forms.Button
$gaming.Text = '🎮 Aquino Gaming Hub'
$gaming.Font = New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)
$gaming.Location = New-Object Drawing.Point(28,210)
$gaming.Size = New-Object Drawing.Size(546,48)
$gaming.Add_Click({
    try {
        Start-Process powershell.exe -ArgumentList @('-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Aquino-GamingHub.ps1'))
        Add-Status 'Gaming Hub aberto.'
    } catch { Add-Status "ERRO: $($_.Exception.Message)" }
})
$form.Controls.Add($gaming)

Add-Status 'Control Center pronto.'
[void]$form.ShowDialog()
