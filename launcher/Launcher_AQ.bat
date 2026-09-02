@echo off
setlocal EnableExtensions
title Android Dex by Aquino - Inicializador

rem Este BAT funciona se estiver na pasta launcher, Android_Dex ou na raiz do projeto.
set "BASEDIR=%~dp0"
for %%I in ("%BASEDIR%.") do set "BASEDIR=%%~fI"

set "ROOT="
if exist "%BASEDIR%\scripts\Start-AndroidDex.ps1" set "ROOT=%BASEDIR%"
if not defined ROOT if exist "%BASEDIR%\..\scripts\Start-AndroidDex.ps1" for %%I in ("%BASEDIR%\..") do set "ROOT=%%~fI"

if not defined ROOT (
    echo.
    echo [ERRO] Nao foi possivel localizar scripts\Start-AndroidDex.ps1.
    echo O Launcher_AQ.bat precisa estar na raiz, em launcher ou em Android_Dex.
    echo.
    pause
    exit /b 10
)

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

rem Registra os atalhos aquino://, mas nao impede o launcher se houver falha.
if exist "%PROTOCOL%" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%PROTOCOL%" -Root "%ROOT%" >nul 2>nul
)

rem O bootstrap abre o runtime correto, prepara o Remote Bridge/ADB e monitora o Dex.
start "Android Dex by Aquino" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%BOOTSTRAP%"
if errorlevel 1 (
    echo.
    echo [ERRO] O Windows nao conseguiu iniciar o PowerShell do Android Dex.
    echo Tente executar este BAT como usuario normal e verifique o Windows Defender.
    echo.
    pause
    exit /b 13
)

endlocal
exit /b 0
