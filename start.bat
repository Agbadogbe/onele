@echo off
REM Demarre l'API, le serveur temps reel et l'espace d'administration.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start.ps1" %*
if errorlevel 1 (
  echo.
  echo   Le demarrage s'est arrete sur une erreur.
  pause
)
