@echo off
setlocal
cd /d "%~dp0"
set "NEON_LOCAL_SIGN_SCRIPT=%~dp0podpisz.ps1"
echo Neon Block Master - lokalne podpisywanie aktualizacji
echo Klucz i haslo pozostaja na Twoim komputerze.
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -Command "$ErrorActionPreference='Stop'; try { Unblock-File -LiteralPath $env:NEON_LOCAL_SIGN_SCRIPT; & $env:NEON_LOCAL_SIGN_SCRIPT } catch { Write-Host $_; exit 1 }"
set "neon_sign_result=%ERRORLEVEL%"
echo.
if not "%neon_sign_result%"=="0" echo Podpis nie zostal utworzony. Przeczytaj blad powyzej.
pause
exit /b %neon_sign_result%
