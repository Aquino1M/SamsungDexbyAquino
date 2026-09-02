[CmdletBinding()]
param([int]$PollMilliseconds=900)
$ErrorActionPreference='SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot 'AndroidDex.Aquino.psm1') -Force
$root=Get-AquinoRoot
$markerDir=Join-Path $root 'runtime\managed-scrcpy'
New-Item -ItemType Directory -Force -Path $markerDir|Out-Null
$attempts=@{}
Start-Sleep -Seconds 2
while($true){
    $dex=Get-Process Android_Dex -ErrorAction SilentlyContinue|Where-Object MainWindowHandle -ne 0|Select-Object -First 1
    if(-not $dex){Start-Sleep -Seconds 2;if(-not(Get-Process Android_Dex -ErrorAction SilentlyContinue)){break};continue}
    foreach($p in @(Get-Process scrcpy -ErrorAction SilentlyContinue|Where-Object MainWindowHandle -ne 0)){
        $lock=Join-Path $markerDir ("$($p.Id).lock")
        if(Test-Path $lock){continue}
        if($attempts.ContainsKey($p.Id) -and ((Get-Date)-$attempts[$p.Id]).TotalSeconds -lt 10){continue}
        $attempts[$p.Id]=Get-Date
        $pkg=''
        try{
            $wp=Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)" -ErrorAction Stop
            $cmd=[string]$wp.CommandLine
            if($cmd -match '(?i)--start-app(?:=|\s+)\+?([^\s"'']+)'){$pkg=$matches[1]}
        }catch{}
        $args=@('-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',(Join-Path $PSScriptRoot 'Aquino-GameShell.ps1'),'-AttachPid',[string]$p.Id)
        if($pkg){$args+=@('-Package',$pkg)}
        Start-Process powershell.exe -ArgumentList $args -WindowStyle Hidden
    }
    foreach($id in @($attempts.Keys)){
        if(-not(Get-Process -Id $id -ErrorAction SilentlyContinue)){$attempts.Remove($id)}
    }
    Start-Sleep -Milliseconds ([Math]::Max(300,$PollMilliseconds))
}
