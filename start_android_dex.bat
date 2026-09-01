@echo off
setlocal
cd /d "%~dp0"
if not exist "Android_Dex\Android_Dex.exe" (
  echo Android_Dex.exe nao encontrado em "%~dp0Android_Dex".
  pause
  exit /b 1
)
start "" "%~dp0Android_Dex\Android_Dex.exe"
endlocal
