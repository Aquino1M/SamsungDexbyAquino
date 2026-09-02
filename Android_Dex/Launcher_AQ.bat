@echo off
setlocal EnableExtensions
title Android Dex by Aquino - Inicializador

set "BASEDIR=%~dp0"
for %%I in ("%BASEDIR%..") do set "ROOT=%%~fI"
set "RUNTIME=%ROOT%\Android_Dex\Android_Dex.exe"
set "BOOTSTRAP=%ROOT%\scripts\Start-AndroidDex.ps1"
set "PROTOCOL=%ROOT%\scripts\Register-AquinoProtocol.ps1"

if not exist "%RUNTIME%" (
    echo.
    echo [ERRO] Android_Dex.exe nao encontrado:
    echo %RUNTIME%
    echo.
    pause
    exit /b 11
)

if not exist "%BOOTSTRAP%" (
    echo.
    echo [ERRO] Start-AndroidDex.ps1 nao encontrado:
    echo %BOOTSTRAP%
    echo.
    pause
    exit /b 12
)

if exist "%PROTOCOL%" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%PROTOCOL%" -Root "%ROOT%" >nul 2>nul

start "Android Dex by Aquino" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%BOOTSTRAP%"
if errorlevel 1 (
    echo.
    echo [ERRO] Nao foi possivel iniciar o Android Dex.
    echo.
    pause
    exit /b 13
)

endlocal
exit /b 0
