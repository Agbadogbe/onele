#Requires -Version 5.1
<#
    Installation complete d'Onele sur Windows.

    Deux principes :
      - ce qui manque est installe automatiquement dans tools\, sans droits
        administrateur et sans rien changer au systeme (voir outils.ps1) ;
      - tout ce qui touche a la base et au .env est delegue a
        `php artisan onele:installer`, partage avec le script Unix : la logique
        n'existe qu'une fois, il n'y a donc pas deux comportements possibles.
#>

$ErrorActionPreference = 'Stop'
$racine = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'outils.ps1')

# Un seul filet pour tout le script : sans lui, `powershell -File` peut rendre
# un code de sortie nul apres une erreur, et le .bat croirait a une reussite.
try {

    Write-Host ""
    Write-Host "  Onélé — installation" -ForegroundColor White
    Write-Host "  --------------------" -ForegroundColor DarkGray

    # ------------------------------------------------------------ Prerequis
    Etape 'Outils'
    $outils = Resoudre-Outils -Racine $racine -Installer -AvecComposer
    if ($outils.Flutter) { Bien 'Flutter détecté' } else { Note 'Flutter absent — le mobile sera ignoré' }
    Enregistrer-Outils -Outils $outils -Racine $racine

    # -------------------------------------------------------------- Backend
    Etape 'API Laravel'
    Push-Location (Join-Path $racine 'backend')
    try {
        $arguments = @($outils.ComposerPrefixe) + @('install', '--no-interaction', '--prefer-dist')
        & $outils.ComposerFichier @arguments
        if ($LASTEXITCODE -ne 0) { throw 'composer install a échoué' }

        & $outils.Php 'artisan' 'onele:installer'
        if ($LASTEXITCODE -ne 0) { throw "l'installateur a échoué" }
    }
    finally { Pop-Location }

    # ------------------------------------------------------------------ Web
    Etape 'Espace d''administration'
    Push-Location (Join-Path $racine 'web')
    try {
        if (-not (Test-Path '.env')) {
            Copy-Item '.env.example' '.env'
            Bien 'Création du fichier web/.env'
        }

        & $outils.Npm 'install' '--no-audit' '--no-fund'
        if ($LASTEXITCODE -ne 0) { throw 'npm install a échoué' }
    }
    finally { Pop-Location }

    # --------------------------------------------------------------- Mobile
    if ($outils.Flutter) {
        Etape 'Application mobile'
        Push-Location (Join-Path $racine 'mobile')
        try {
            & flutter pub get
            if ($LASTEXITCODE -ne 0) { throw 'flutter pub get a échoué' }
        }
        finally { Pop-Location }
    }

    # -------------------------------------------------------- Le mot de la fin
    Write-Host ""
    Write-Host "  Installation terminée." -ForegroundColor Green
    Write-Host ""
    Write-Host "  Pour tout démarrer :" -ForegroundColor White
    Write-Host "      .\start.bat" -ForegroundColor Yellow
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "  Échec : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
