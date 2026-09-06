#Requires -Version 5.1
<#
    Lance l'application mobile d'Onele.

    Flutter est installe automatiquement s'il manque, comme PHP et Node. La
    cible est choisie dans cet ordre : un telephone Android branche en USB, un
    emulateur deja demarre, sinon Chrome. Le navigateur n'est pas un pis-aller
    complet mais il montre la meme application, avec les memes ecrans.
#>

$ErrorActionPreference = 'Stop'
$racine = Split-Path -Parent $PSScriptRoot
$mobile = Join-Path $racine 'mobile'
. (Join-Path $PSScriptRoot 'outils.ps1')

function Choisir-Cible([string]$flutter) {
    # --machine donne du JSON : plus sur que de lire un tableau destine a l'oeil.
    try {
        $brut = (& $flutter devices --machine | Out-String)
        $appareils = $brut | ConvertFrom-Json
    } catch {
        return @{ Id = 'chrome'; Nom = 'Chrome' }
    }

    $telephone = $appareils | Where-Object { $_.targetPlatform -like 'android*' -and -not $_.emulator } | Select-Object -First 1
    if ($telephone) { return @{ Id = $telephone.id; Nom = "$($telephone.name) (téléphone branché)" } }

    $emulateur = $appareils | Where-Object { $_.emulator } | Select-Object -First 1
    if ($emulateur) { return @{ Id = $emulateur.id; Nom = "$($emulateur.name) (émulateur)" } }

    return @{ Id = 'chrome'; Nom = 'Chrome' }
}

try {

    Write-Host ""
    Write-Host "  Onélé — application mobile" -ForegroundColor White
    Write-Host "  --------------------------" -ForegroundColor DarkGray

    # ------------------------------------------------- L'API doit repondre
    $apiPrete = $false
    try {
        Invoke-WebRequest -Uri 'http://127.0.0.1:8000' -UseBasicParsing -TimeoutSec 3 | Out-Null
        $apiPrete = $true
    } catch {
        # Traite juste en dessous.
    }
    if (-not $apiPrete) {
        Write-Host ""
        Write-Host "  L'API ne répond pas sur le port 8000." -ForegroundColor Red
        Write-Host "  Lancez .\start.bat d'abord, puis revenez ici." -ForegroundColor Red
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

    $cible = Choisir-Cible $flutter

    Etape 'Lancement'
    Note "Cible : $($cible.Nom)"
    if ($cible.Id -eq 'chrome') {
        Note 'Aucun téléphone ni émulateur détecté — l''application s''ouvre dans Chrome.'
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
