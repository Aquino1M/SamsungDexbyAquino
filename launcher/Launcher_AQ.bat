@echo off
setlocal
set "DEXDIR=%~dp0"
for %%I in ("%DEXDIR%..") do set "ROOT=%%~fI"

rem Prepara o protocolo usado por Configuracoes > Jogos, Gamepad e Atualizacoes.
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%ROOT%\scripts\Register-AquinoProtocol.ps1" -Root "%ROOT%" >nul 2>nul

if not exist "%DEXDIR%Android_Dex.exe" (
  msg * "Android Dex by Aquino: Android_Dex.exe nao encontrado. Reextraia o pacote completo."
  exit /b 1
)
start "" /D "%DEXDIR%" "%DEXDIR%Android_Dex.exe"
endlocal
