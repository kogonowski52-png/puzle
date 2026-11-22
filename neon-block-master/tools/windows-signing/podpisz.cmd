@echo off
cd /d "%~dp0"
echo Neon Block Master - lokalne podpisywanie AAB
echo Klucz i haslo pozostaja na Twoim komputerze.
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0podpisz.ps1"
set "neon_sign_result=%ERRORLEVEL%"
echo.
if not "%neon_sign_result%"=="0" echo Podpis nie zostal utworzony. Przeczytaj blad powyzej.
pause
exit /b %neon_sign_result%
