@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-agent.ps1"
if errorlevel 1 (
  echo.
  echo 安装失败，请把上面的错误信息截图发给开发者。
  pause
)
endlocal
