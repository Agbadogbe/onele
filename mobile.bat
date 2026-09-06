@echo off
REM Lance l'application mobile. Flutter est installe automatiquement
REM s'il manque. L'API doit tourner : lancez start.bat avant.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\mobile.ps1" %*
if errorlevel 1 (
  echo.
  echo   Le lancement s'est arrete sur une erreur.
  pause
)
