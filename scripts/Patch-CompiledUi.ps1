[CmdletBinding()]
param(
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$app = Join-Path $Root 'Android_Dex\data\app.so'
if (-not (Test-Path -LiteralPath $app)) { throw "app.so nao encontrado: $app" }

$backup = "$app.upstream-backup"
if (-not (Test-Path -LiteralPath $backup)) {
    Copy-Item -LiteralPath $app -Destination $backup
    Write-Host "Backup criado: $backup"
}

$bytes = [System.IO.File]::ReadAllBytes($app)
$latin1 = [System.Text.Encoding]::GetEncoding(28591)
$utf16 = [System.Text.Encoding]::Unicode

function Set-OneByteString([int]$Offset, [int]$Capacity, [string]$Text) {
    $data = $latin1.GetBytes($Text)
    if ($data.Length -gt $Capacity) { throw "Texto excede capacidade em 0x$($Offset.ToString('X')): $Text" }
    [BitConverter]::GetBytes([Int64]($Text.Length * 2)).CopyTo($bytes, $Offset - 8)
    for ($i = 0; $i -lt $Capacity; $i++) { $bytes[$Offset + $i] = 0 }
    [Array]::Copy($data, 0, $bytes, $Offset, $data.Length)
}

function Set-TwoByteString([int]$Offset, [int]$CapacityUnits, [string]$Text) {
    $data = $utf16.GetBytes($Text)
    $units = [int]($data.Length / 2)
    if ($units -gt $CapacityUnits) { throw "Texto excede capacidade em 0x$($Offset.ToString('X')): $Text" }
    [BitConverter]::GetBytes([Int64]($units * 2)).CopyTo($bytes, $Offset - 8)
    for ($i = 0; $i -lt ($CapacityUnits * 2); $i++) { $bytes[$Offset + $i] = 0 }
    [Array]::Copy($data, 0, $bytes, $Offset, $data.Length)
}

# Rodape principal: compacto para dar area ao botao GitHub Aquino1M.
Set-OneByteString 0x321570 16 'Base Shrey'
Set-OneByteString 0x3500A0 16 'AQ'
Set-OneByteString 0x274E20 16 'GitHub Aquino1M'
Set-OneByteString 0x33E530 16 'GitHub Aquino1M'
Set-OneByteString 0x3498F0 32 'https://github.com/Aquino1M'

# Configuracoes Aquino: jogos, gamepad e atualizacoes dentro da pagina Sobre.
Set-OneByteString 0x356260 32 'Jogos, Gamepad e Atualizações'
Set-OneByteString 0x296390 48 'Perfis · Gamepad · FPS · Atualizações'
Set-OneByteString 0x346490 32 'RECURSOS AQUINO1M'
Set-OneByteString 0x2791C0 48 'Projeto Aquino1M (SamsungDex)'
Set-OneByteString 0x2A9C40 64 'Repositório Aquino1M · Launcher · Gaming · Atualizações'
Set-OneByteString 0x38B9A0 40 'Configurar Jogos e Gamepad'
Set-OneByteString 0x380050 80 'Mapeamento tipo BlueStacks · Teclado · Mouse · Controle'
Set-OneByteString 0x3987F0 48 'https://github.com/Aquino1M/SamsungDexbyAquino'
Set-OneByteString 0x27B490 40 'aquino-gamepad://open'
Set-OneByteString 0x3A3A50 48 'https://github.com/Aquino1M/SamsungDexbyAquino'
Set-OneByteString 0x3B9900 64 'V1.3 Aquino: Gamepad, KeyMapper e Gaming Hub atualizados.'

# Widget inicial: reduz o texto da esquerda para o botao GitHub Aquino1M caber sem corte.
Set-TwoByteString 0x314E50 23 'V.1.3 · Aquino1M'

# Modal de conexao: duas abas uteis.
Set-OneByteString 0x3B5050 32 'Guia rápido PT-BR'
Set-OneByteString 0x2DA5D0 32 'Atualizações'
Set-OneByteString 0x2AEDD0 16 'Pronto'
Set-OneByteString 0x327D80 32 'Guia de Conexao Android'
Set-OneByteString 0x331330 64 'Conecte seu Android por USB ou pela mesma rede Wi-Fi.'
Set-OneByteString 0x2EBC30 16 'Guia de Conexao'

# Guia PT-BR.
Set-OneByteString 0x28CDC0 32 'Passos conexao USB'
Set-OneByteString 0x3D64B0 32 'Ative Opcoes Desenvolvedor'
Set-TwoByteString 0x39F6B0 104 'Abra Configuracoes > Sobre o telefone, toque 7x em Numero da versao e libere Opcoes do Desenvolvedor.'
Set-OneByteString 0x2B0C50 32 'Ative Depuracao USB'
Set-TwoByteString 0x2B0A40 64 'Configuracoes > Opcoes do Desenvolvedor > Ative Depuracao USB.'
Set-OneByteString 0x362FC0 32 'Conecte USB e autorize PC'
Set-OneByteString 0x3B5CC0 96 'Conecte o USB ao PC. No celular, autorize este computador e marque Sempre permitir.'
Set-OneByteString 0x35D480 32 'Passos conexao Wi-Fi / TCP'
Set-OneByteString 0x2EBB90 32 'Use mesma rede Wi-Fi'
Set-OneByteString 0x2A71C0 80 'Deixe o PC Windows e o Android conectados exatamente na mesma rede Wi-Fi.'
Set-OneByteString 0x31EA70 32 'Ative Depuracao sem Fio'
Set-TwoByteString 0x36C730 80 'Em Opcoes do Desenvolvedor, ative Depuracao sem Fio e anote o IP e a porta.'
Set-OneByteString 0x2E6A10 32 'Digite IP no Gerenciador'
Set-OneByteString 0x327F50 80 'Digite IP do celular (ex. 192.168.1.100:5555) no TCP/IP e clique Conectar.'

# Segunda aba: filtros de novidades no lugar dos idiomas antigos.
Set-OneByteString 0x2F7770 16 'Todos'
Set-OneByteString 0x3A4210 16 'DESTAQUE'
Set-TwoByteString 0x332180 16 'Destaques'
Set-TwoByteString 0x2DBA70 16 'Launcher'
Set-TwoByteString 0x39B6E0 16 'Interface'
Set-TwoByteString 0x396320 16 'Gaming'
Set-TwoByteString 0x36D8C0 16 'Conexao'
Set-TwoByteString 0x3D4860 16 'FPS'
Set-TwoByteString 0x3A8760 16 'Proximas'

# Cards de atualizacoes/novidades do launcher.
Set-OneByteString 0x396BA0 64 'V1.3 Aquino: jogos e controles integrados'
Set-TwoByteString 0x358C80 64 'Launcher Aquino abre o runtime editado correto'
Set-TwoByteString 0x2C4CB0 56 'Configuracoes agora tem Jogos e Gamepad'
Set-OneByteString 0x311BF0 48 'Recursos apontam para Aquino1M'
Set-OneByteString 0x3CCB20 64 'GitHub Aquino1M ajustado no widget inicial'
Set-OneByteString 0x390190 96 'Rodape e identificacao Aquino reorganizados'
Set-TwoByteString 0x2BB530 40 'Menu e interface mais limpos'
Set-TwoByteString 0x2A6660 56 'Editor tipo BlueStacks: teclado, mouse e gamepad'
Set-OneByteString 0x3CF180 96 'Jogos agora podem abrir integrados dentro do Android Dex'
Set-TwoByteString 0x27A130 40 'Gamepad Xbox / DualSense via UHID'
Set-OneByteString 0x3493B0 80 'Mapeamento salvo por jogo e package Android'
Set-OneByteString 0x32C250 64 'Analogicos e botoes do gamepad configuraveis'
Set-OneByteString 0x3E48D0 64 'Baixa latencia + gamepad + perfis de desempenho'
Set-TwoByteString 0x3AE870 64 'Novas melhorias Aquino aparecem nesta aba'

# IDs invalidos evitam thumbnails de video; os cards abrem somente o repositorio Aquino.
$ids = @(
    @(0x35A640,'AQUPD000001'), @(0x3B4380,'AQUPD000002'), @(0x337D20,'AQUPD000003'),
    @(0x33F240,'AQUPD000004'), @(0x2A76A0,'AQUPD000005'), @(0x2CCC70,'AQUPD000006'),
    @(0x3DBE20,'AQUPD000007'), @(0x3E18B0,'AQUPD000008'), @(0x358620,'AQUPD000009'),
    @(0x3342D0,'AQUPD000010'), @(0x2F8930,'AQUPD000011'), @(0x34F570,'AQUPD000012'),
    @(0x39EA80,'AQUPD000013'), @(0x29CD60,'AQUPD000014')
)
foreach ($pair in $ids) { Set-OneByteString ([int]$pair[0]) 16 ([string]$pair[1]) }

$urlOffsets = @(0x290D60,0x310670,0x2B8B40,0x329C70,0x2D5600,0x3730A0,0x2F7380,0x36B3C0,0x2A3B60,0x3643F0,0x3A1970,0x2FFC60,0x2FDE30,0x3DB2F0)
foreach ($off in $urlOffsets) { Set-OneByteString $off 48 'https://github.com/Aquino1M/SamsungDexbyAquino' }
Set-OneByteString 0x2F1B80 32 'http://127.0.0.1:1/'
Set-OneByteString 0x2C4F80 16 '.png'

# Rodape do modal mais curto e limpo.
Set-OneByteString 0x393E00 224 'Android Dex by Aquino - V1.3 | Guia e novidades integrados.'

# V1.2 -> V1.3 (mesmo tamanho, substituicao segura em todo o snapshot).
$oldVersion = $latin1.GetBytes('V.1.2')
$newVersion = $latin1.GetBytes('V.1.3')
for ($i = 0; $i -le $bytes.Length - $oldVersion.Length; $i++) {
    $match = $true
    for ($j = 0; $j -lt $oldVersion.Length; $j++) {
        if ($bytes[$i + $j] -ne $oldVersion[$j]) { $match = $false; break }
    }
    if ($match) { [Array]::Copy($newVersion, 0, $bytes, $i, $newVersion.Length) }
}

# Corrige tambem as ocorrencias UTF-16 usadas pelo widget flutuante.
$oldVersion16 = $utf16.GetBytes('V.1.2')
$newVersion16 = $utf16.GetBytes('V.1.3')
for ($i = 0; $i -le $bytes.Length - $oldVersion16.Length; $i++) {
    $match = $true
    for ($j = 0; $j -lt $oldVersion16.Length; $j++) {
        if ($bytes[$i + $j] -ne $oldVersion16[$j]) { $match = $false; break }
    }
    if ($match) { [Array]::Copy($newVersion16, 0, $bytes, $i, $newVersion16.Length) }
}

# Restaura a rotina original do antigo painel de videos e troca a ordem das views:
# primeira aba = guia manual; segunda aba = cards de atualizacoes.
[byte[]]$videoPrefix = 0x55,0x48,0x89,0xE5,0x48
[Array]::Copy($videoPrefix, 0, $bytes, 0x852544, 5)
$call1 = 0x851E2F
$call2 = 0x851E40
$manual = 0x8520F4
$updates = 0x852544
if ($bytes[$call1] -ne 0xE8 -or $bytes[$call2] -ne 0xE8) { throw 'Build app.so diferente da esperada: chamadas do TabBarView nao encontradas.' }
[BitConverter]::GetBytes([int]($manual - ($call1 + 5))).CopyTo($bytes, $call1 + 1)
[BitConverter]::GetBytes([int]($updates - ($call2 + 5))).CopyTo($bytes, $call2 + 1)

[System.IO.File]::WriteAllBytes($app, $bytes)
$hash = (Get-FileHash -LiteralPath $app -Algorithm SHA256).Hash
Write-Host 'Patch Aquino V1.3 / 0.4.0 aplicado com sucesso.'
Write-Host 'Abas: Guia rapido PT-BR + Atualizacoes.'
Write-Host 'Botao: GitHub Aquino1M.'
Write-Host "SHA256: $hash"
Write-Host 'Para restaurar a base, copie app.so.upstream-backup sobre app.so.'
