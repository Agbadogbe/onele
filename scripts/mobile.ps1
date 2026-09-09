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
$PORT_MOBILE = 8090
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

    if (Port-Ouvert $PORT_MOBILE) {
        $adresse = Adresse-Locale
        Write-Host ""
        Bien "L'application mobile tourne déjà sur le port $PORT_MOBILE."
        Note "Sur ce PC          http://localhost:$PORT_MOBILE"
        if ($adresse) { Note "Sur un téléphone   http://${adresse}:$PORT_MOBILE" }
        Note 'Fermez sa fenêtre avant de relancer si vous voulez repartir de zéro.'
        Write-Host ""
        exit 0
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
    Write-Host ""
    Note 'Compte employé : moussa.ndiaye@onele.test / password'
    Note 'La première compilation prend une à deux minutes.'
    Note 'Appuyez sur « q » dans cette fenêtre pour arrêter.'

    if ($cible.Id -eq 'chrome') {
        # Servi sur toutes les interfaces plutot que lance dans un navigateur :
        # l'application devient joignable depuis un telephone du reseau local,
        # et elle deduit seule ou est l'API — c'est l'hote qui l'a servie.
        $adresse = Adresse-Locale
        Write-Host ""
        Note "Sur ce PC          http://localhost:$PORT_MOBILE"
        if ($adresse) {
            Write-Host "  Sur un téléphone   http://${adresse}:$PORT_MOBILE" -ForegroundColor Yellow
            Note 'Même Wi-Fi que ce PC ; aucune installation sur le téléphone.'
        }
        Write-Host ""
        Push-Location $mobile
        try {
            & $flutter run -d web-server --web-hostname=0.0.0.0 --web-port=$PORT_MOBILE
        }
        finally { Pop-Location }
    } else {
        Write-Host ""
        Push-Location $mobile
        try {
            & $flutter run -d $cible.Id
        }
        finally { Pop-Location }
    }
}
catch {
    Write-Host ""
    Write-Host "  Échec : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
