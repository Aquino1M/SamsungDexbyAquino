@echo off
setlocal
cd /d "%~dp0"
if not exist "scripts\Aquino-ControlCenter.ps1" (
  echo Launcher principal nao encontrado em "%~dp0scripts".
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Aquino-ControlCenter.ps1"
endlocal
