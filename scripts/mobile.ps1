#Requires -Version 5.1
<#
    Lance seulement l'application mobile d'Onele, quand l'API tourne deja.
    Pour tout lancer d'un coup, utilisez onele.bat.

    Flutter est installe automatiquement s'il manque, comme PHP et Node. La
    cible est choisie dans cet ordre : un telephone Android branche en USB, un
    emulateur deja demarre, sinon le navigateur. Ce dernier n'est pas un
    telephone, mais il montre la meme application, avec les memes ecrans.
#>

$ErrorActionPreference = 'Stop'
$racine = Split-Path -Parent $PSScriptRoot
$mobile = Join-Path $racine 'mobile'
. (Join-Path $PSScriptRoot 'outils.ps1')

try {

    Write-Host ""
    Write-Host "  Onélé — application mobile" -ForegroundColor White
    Write-Host "  --------------------------" -ForegroundColor DarkGray

    # ------------------------------------------------- L'API doit repondre
    if (-not (Port-Ouvert 8000)) {
        Write-Host ""
        Write-Host "  L'API ne répond pas sur le port 8000." -ForegroundColor Red
        Write-Host "  Lancez .\onele.bat, qui démarre tout d'un coup." -ForegroundColor Red
        Write-Host ""
        exit 1
    }

    Etape 'Outils'
    $flutter = Resoudre-Flutter -Racine $racine -Installer

    Etape 'Dépendances'
    Push-Location $mobile
    try {
        & $flutter pub get
        if ($LASTEXITCODE -ne 0) { throw 'flutter pub get a échoué' }
    }
    finally { Pop-Location }

    $navigateur = Resoudre-Navigateur
    if ($navigateur) { Note "Chrome absent — l'application s'ouvrira dans Edge." }

    $cible = Choisir-Cible $flutter

    Etape 'Lancement'
    Note "Cible : $($cible.Nom)"
    if ($cible.Id -eq 'chrome') {
        Note 'Aucun téléphone ni émulateur détecté — l''application s''ouvre dans le navigateur.'
        Note 'Réduisez la fenêtre à la largeur d''un téléphone pour la voir telle qu''elle est prévue.'
    }
    Write-Host ""
    Note 'Compte employé : moussa.ndiaye@onele.test / password'
    Note 'La première compilation prend une à deux minutes.'
    Note 'Appuyez sur « q » dans cette fenêtre pour arrêter.'
    Write-Host ""

    Push-Location $mobile
    try {
        & $flutter run -d $cible.Id
    }
    finally { Pop-Location }
}
catch {
    Write-Host ""
    Write-Host "  Échec : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
