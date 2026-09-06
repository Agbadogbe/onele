@echo off
REM Onele, d'un seul geste : installe ce qui manque puis lance le web
REM et le mobile. Rejouable sans dommage.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\onele.ps1" %*
if errorlevel 1 (
  echo.
  echo   Le lancement s'est arrete sur une erreur.
  pause
)
