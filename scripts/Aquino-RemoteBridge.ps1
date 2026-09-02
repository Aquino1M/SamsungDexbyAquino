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
$listener = [System.Net.HttpListener]::new(); $listener.Prefixes.Add("http://+:$Port/")
try { $listener.Start() } catch { throw "Nao foi possivel iniciar Aquino Remote na porta $Port. $($_.Exception.Message)" }
Write-Host "Aquino Remote Bridge ativo em http://0.0.0.0:$Port/"; Write-Host "Token: $token"
function Reply($ctx,[int]$code,[object]$obj) { $json=$obj|ConvertTo-Json -Compress -Depth 4; $b=[Text.Encoding]::UTF8.GetBytes($json); $ctx.Response.StatusCode=$code; $ctx.Response.ContentType='application/json; charset=utf-8'; $ctx.Response.ContentLength64=$b.Length; $ctx.Response.OutputStream.Write($b,0,$b.Length); $ctx.Response.Close() }
function Invoke-Action([string]$name) { switch ($name) {
'focus' { $p=Get-Process Android_Dex -ErrorAction SilentlyContinue|Select-Object -First 1; if(-not $p){Start-Process (Join-Path $Root 'Android_Dex\Android_Dex.exe')} }
'gaming_hub' { Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $Root 'scripts\Aquino-GamingHub.ps1')) }
'gamepad_editor' { Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $Root 'scripts\Aquino-GamepadEditor.ps1')) }
'keymapper' { Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $Root 'scripts\Aquino-KeyMapper.ps1')) }
'fullscreen' { $p=Get-Process Android_Dex -ErrorAction Stop|Where-Object MainWindowHandle -ne 0|Select-Object -First 1; Set-AquinoBorderlessFullscreen -Process $p }
'repair_adb' { $adb=Resolve-AquinoAdb -Root $Root; [void](Repair-AquinoAdb -AdbPath $adb -Retries 3) }
'wireless_adb' { Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $Root 'scripts\Wireless-Adb.ps1')) }
'diagnostics' { Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $Root 'scripts\Diagnostics.ps1')) }
'close_dex' { Get-Process Android_Dex -ErrorAction SilentlyContinue|Stop-Process -Force }
default { throw "Acao desconhecida: $name" } } }
while ($listener.IsListening) { $ctx=$listener.GetContext(); try {
if ($ctx.Request.Headers['X-Aquino-Token'] -ne $token) { Reply $ctx 401 @{error='token invalido'}; continue }
if ($ctx.Request.Url.AbsolutePath -eq '/status') { $adbOnline=$false; try{$adb=Resolve-AquinoAdb -Root $Root;$adbOnline=Test-AquinoAdbServer -AdbPath $adb}catch{}; Reply $ctx 200 @{dexRunning=[bool](Get-Process Android_Dex -ErrorAction SilentlyContinue);adbOnline=$adbOnline;version='0.5.0';project='Aquino1M/SamsungDexbyAquino'}; continue }
if ($ctx.Request.Url.AbsolutePath -eq '/action' -and $ctx.Request.HttpMethod -eq 'POST') { $r=[IO.StreamReader]::new($ctx.Request.InputStream,$ctx.Request.ContentEncoding);$body=$r.ReadToEnd()|ConvertFrom-Json;Invoke-Action ([string]$body.action);Reply $ctx 200 @{ok=$true;action=$body.action};continue }
Reply $ctx 404 @{error='not found'} } catch { Reply $ctx 500 @{error=$_.Exception.Message} } }
