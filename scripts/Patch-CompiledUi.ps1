[CmdletBinding()]
param(
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$app = Join-Path $Root 'Android_Dex\data\app.so'
if (-not (Test-Path $app)) { throw "app.so nao encontrado: $app" }

$backup = "$app.upstream-backup"
if (-not (Test-Path $backup)) {
    Copy-Item $app $backup
    Write-Host "Backup criado: $backup"
}

$enc = [System.Text.Encoding]::GetEncoding(28591)
$bytes = [System.IO.File]::ReadAllBytes($app)
$text = $enc.GetString($bytes)

function Fit([string]$old, [string]$new) {
    if ($new.Length -gt $old.Length) { throw "Texto novo maior que o original: $old" }
    return $new + (' ' * ($old.Length - $new.Length))
}

$patches = [ordered]@{
    'Powered by' = 'Base Shrey'
    'Desenvolvido por' = 'Melhorado por AQ'
    'Device Connection Guide' = 'Guia de Conexao Android'
    'Pair your Android phone via USB cable or Wi-Fi network' = 'Conecte seu Android por USB ou pela mesma rede Wi-Fi.'
    'Step 1: Video Tutorials' = 'Tutorial: Portugues BR!'
    'Step 2: Manual Steps' = 'Passos manuais PT-BR'
    'Got It' = 'Pronto'
    'Connection Guide' = 'Guia de Conexao'
    'USB Connection Steps' = 'Passos conexao USB'
    'Wi-Fi / TCP IP Connection Steps' = 'Passos conexao Wi-Fi / TCP'
    'Connect USB & Authorize PC' = 'Conecte USB e autorize PC'
    'Enable Wireless Debugging' = 'Ative Depuracao sem Fio'
    'Connect to Same Wi-Fi' = 'Use mesma rede Wi-Fi'
}

foreach ($entry in $patches.GetEnumerator()) {
    $replacement = Fit $entry.Key $entry.Value
    if ($text.Contains($entry.Key)) {
        $text = $text.Replace($entry.Key, $replacement)
        Write-Host "OK: $($entry.Key) -> $($entry.Value)"
    }
}

$oldFooter = 'Special thanks to the independent community creators for publishing these helpful YouTube tutorials. These videos are created independently to assist users and are not sponsored by or affiliated with developer '
$newFooter = 'Tutorial da edicao Aquino: conecte o celular por USB, ative Opcoes do Desenvolvedor e Depuracao USB, autorize este computador e siga os passos manuais em Portugues. Videos externos nao sao necessarios.'
if ($text.Contains($oldFooter)) {
    $text = $text.Replace($oldFooter, (Fit $oldFooter $newFooter))
}

# O handle em minusculas e usado na UI e no link de perfil. Ambos possuem 8 caracteres.
$text = $text.Replace('shrey113', 'Aquino1M')

# Troca somente a primeira ocorrencia standalone de Shrey113; URLs do upstream continuam intactas.
$needle = 'Shrey113'
$start = 0
while ($true) {
    $idx = $text.IndexOf($needle, $start, [System.StringComparison]::Ordinal)
    if ($idx -lt 0) { break }
    $ctxStart = [Math]::Max(0, $idx - 40)
    $ctx = $text.Substring($ctxStart, $idx - $ctxStart)
    if (-not $ctx.Contains('github.com') -and -not $ctx.Contains('api.github.com')) {
        $text = $text.Remove($idx, 8).Insert($idx, 'Aquino1M')
        break
    }
    $start = $idx + 1
}

[System.IO.File]::WriteAllBytes($app, $enc.GetBytes($text))

$notice = @'
Android Dex by Aquino - Enhanced/Gaming Edition

Base application: Android-Dex by Shrey113 (closed-source upstream build).
Enhanced/Gaming layer, launchers, diagnostics, compatibility profiles and Aquino customizations: Aquino / Aquino1M.
Official Aquino repository: https://github.com/Aquino1M/SamsungDexbyAquino

The Aquino name refers to the Enhanced/Gaming modifications and distribution layer, not authorship of the closed-source upstream application.
'@
Set-Content -Path (Join-Path $Root 'Android_Dex\AQUINO_ENHANCED_NOTICE.txt') -Value $notice -Encoding UTF8

Write-Host 'Patch Aquino aplicado com sucesso.'
Write-Host 'Para restaurar a base, copie app.so.upstream-backup sobre app.so.'
