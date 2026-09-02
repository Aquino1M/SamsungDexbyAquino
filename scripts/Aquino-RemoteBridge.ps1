[CmdletBinding()]
param([string]$Root = (Split-Path $PSScriptRoot -Parent), [int]$Port = 37891)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'AndroidDex.Aquino.psm1') -Force

$tokenFile = Join-Path $Root 'config\remote-token.txt'
if (-not (Test-Path $tokenFile)) {
    $token = -join ((48..57)+(65..90) | Get-Random -Count 8 | ForEach-Object {[char]$_})
    New-Item -ItemType Directory -Force -Path (Split-Path $tokenFile) | Out-Null
    Set-Content -Path $tokenFile -Value $token -Encoding ASCII
} else { $token = (Get-Content $tokenFile -Raw).Trim() }

# TcpListener evita a exigencia de URLACL do HttpListener no Windows.
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
$listener.Start()
Write-Host "Aquino Remote Bridge ativo na porta $Port."
Write-Host "Token: $token"

function Invoke-Action([string]$name) {
    switch ($name) {
        'focus' { $p=Get-Process Android_Dex -ErrorAction SilentlyContinue|Select-Object -First 1; if(-not $p){Start-Process (Join-Path $Root 'Android_Dex\Android_Dex.exe')} }
        'gaming_hub' { Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $Root 'scripts\Aquino-GamingHub.ps1')) }
        'gamepad_editor' { Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $Root 'scripts\Aquino-GamepadEditor.ps1')) }
        'keymapper' { Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $Root 'scripts\Aquino-KeyMapper.ps1')) }
        'fullscreen' { $p=Get-Process Android_Dex -ErrorAction Stop|Where-Object MainWindowHandle -ne 0|Select-Object -First 1; Set-AquinoBorderlessFullscreen -Process $p }
        'repair_adb' { $adb=Resolve-AquinoAdb -Root $Root; [void](Repair-AquinoAdb -AdbPath $adb -Retries 3) }
        'wireless_adb' { Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $Root 'scripts\Wireless-Adb.ps1')) }
        'diagnostics' { Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $Root 'scripts\Diagnostics.ps1')) }
        'close_dex' { Get-Process Android_Dex -ErrorAction SilentlyContinue|Stop-Process -Force }
        default { throw "Acao desconhecida: $name" }
    }
}

function Send-Json($stream, [int]$code, [object]$obj) {
    $json = $obj | ConvertTo-Json -Compress -Depth 4
    $body = [Text.Encoding]::UTF8.GetBytes($json)
    $reason = switch ($code) { 200 {'OK'} 400 {'Bad Request'} 401 {'Unauthorized'} 404 {'Not Found'} default {'Internal Server Error'} }
    $header = "HTTP/1.1 $code $reason`r`nContent-Type: application/json; charset=utf-8`r`nContent-Length: $($body.Length)`r`nConnection: close`r`nAccess-Control-Allow-Origin: *`r`n`r`n"
    $hb = [Text.Encoding]::ASCII.GetBytes($header)
    $stream.Write($hb,0,$hb.Length); $stream.Write($body,0,$body.Length); $stream.Flush()
}

while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
        $stream = $client.GetStream()
        $reader = [IO.StreamReader]::new($stream,[Text.Encoding]::ASCII,$false,4096,$true)
        $requestLine = $reader.ReadLine()
        if ([string]::IsNullOrWhiteSpace($requestLine)) { Send-Json $stream 400 @{error='requisicao vazia'}; continue }
        $parts = $requestLine.Split(' ')
        $method = $parts[0]; $path = $parts[1]
        $headers = @{}
        while ($true) {
            $line = $reader.ReadLine(); if ($null -eq $line -or $line -eq '') { break }
            $idx = $line.IndexOf(':'); if ($idx -gt 0) { $headers[$line.Substring(0,$idx).Trim().ToLowerInvariant()] = $line.Substring($idx+1).Trim() }
        }
        if ($headers['x-aquino-token'] -ne $token) { Send-Json $stream 401 @{error='token invalido'}; continue }
        $bodyText = ''
        $len = 0; if ($headers.ContainsKey('content-length')) { [void][int]::TryParse($headers['content-length'],[ref]$len) }
        if ($len -gt 0) { $chars = New-Object char[] $len; $read=0; while($read -lt $len){$n=$reader.Read($chars,$read,$len-$read);if($n -le 0){break};$read+=$n}; if($read -gt 0){ $bodyText = -join $chars[0..($read-1)] } }

        if ($method -eq 'GET' -and $path -eq '/status') {
            $adbOnline=$false; try{$adb=Resolve-AquinoAdb -Root $Root;$adbOnline=Test-AquinoAdbServer -AdbPath $adb}catch{}
            Send-Json $stream 200 @{dexRunning=[bool](Get-Process Android_Dex -ErrorAction SilentlyContinue);adbOnline=$adbOnline;version='0.5.0';project='Aquino1M/SamsungDexbyAquino'}
        } elseif ($method -eq 'POST' -and $path -eq '/action') {
            $body = $bodyText | ConvertFrom-Json; Invoke-Action ([string]$body.action); Send-Json $stream 200 @{ok=$true;action=$body.action}
        } else { Send-Json $stream 404 @{error='not found'} }
    } catch {
        try { Send-Json $stream 500 @{error=$_.Exception.Message} } catch {}
    } finally { $client.Close() }
}
