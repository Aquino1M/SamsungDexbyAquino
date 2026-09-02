@echo off
setlocal EnableExtensions
title Android Dex by Aquino
set "ROOT=%~dp0"
for %%I in ("%ROOT%.") do set "ROOT=%%~fI"
set "BOOTSTRAP=%ROOT%\scripts\Start-AndroidDex.ps1"
set "RUNTIME=%ROOT%\Android_Dex\Android_Dex.exe"

if not exist "%BOOTSTRAP%" (
    echo [ERRO] scripts\Start-AndroidDex.ps1 nao encontrado.
    pause
    exit /b 1
)
if not exist "%RUNTIME%" (
    echo [ERRO] Android_Dex\Android_Dex.exe nao encontrado.
    pause
    exit /b 2
)

start "Android Dex by Aquino" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%BOOTSTRAP%"
if errorlevel 1 (
    echo [ERRO] Falha ao iniciar o Android Dex.
    pause
    exit /b 3
)

endlocal
exit /b 0
