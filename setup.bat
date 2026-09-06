@echo off
REM Amorce l'installation depuis l'Explorateur comme depuis une invite de
REM commandes. `-ExecutionPolicy Bypass` evite le blocage par defaut de
REM Windows sur les scripts .ps1 telecharges.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup.ps1" %*
if errorlevel 1 (
  echo.
  echo   L'installation s'est arretee sur une erreur.
  pause
)
