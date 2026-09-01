@echo off
setlocal
cd /d "%~dp0"
if not exist "Android_Dex\Android_Dex.exe" (
  echo Android_Dex.exe nao encontrado em "%~dp0Android_Dex".
  pause
  exit /b 1
)
pushd "%~dp0Android_Dex"
start "" "Android_Dex.exe"
popd
exit /b 0
