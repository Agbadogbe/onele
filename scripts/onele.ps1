#Requires -Version 5.1
<#
    Onele, d'un seul geste : installe ce qui manque, demarre l'API, le serveur
    temps reel, l'espace d'administration et l'application mobile.

    Rejouable sans dommage : ce qui est deja installe n'est pas reinstalle, et
    un service deja en route n'est pas lance une seconde fois.
#>

$ErrorActionPreference = 'Stop'
$racine  = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $racine 'backend'
$web     = Join-Path $racine 'web'
$mobile  = Join-Path $racine 'mobile'
. (Join-Path $PSScriptRoot 'outils.ps1')

try {

    Write-Host ""
    Write-Host "  Onélé" -ForegroundColor White
    Write-Host "  -----" -ForegroundColor DarkGray
    Note 'La première fois, comptez un moment : tout ce qui manque est téléchargé.'

    # ------------------------------------------------------------- Prerequis
    Etape 'Outils'
    $outils = Resoudre-Outils -Racine $racine -Installer -AvecComposer
    Enregistrer-Outils -Outils $outils -Racine $racine

    # --------------------------------------------------------------- Backend
    Etape 'API Laravel'
    Push-Location $backend
    try {
        $arguments = @($outils.ComposerPrefixe) + @('install', '--no-interaction', '--prefer-dist')
        & $outils.ComposerFichier @arguments
        if ($LASTEXITCODE -ne 0) { throw 'composer install a échoué' }

        & $outils.Php 'artisan' 'onele:installer'
        if ($LASTEXITCODE -ne 0) { throw "l'installateur a échoué" }
    }
    finally { Pop-Location }

    # ------------------------------------------------------------------- Web
    Etape 'Espace d''administration'
    Push-Location $web
    try {
        if (-not (Test-Path '.env')) {
            Copy-Item '.env.example' '.env'
            Bien 'Création du fichier web/.env'
        }
        & $outils.Npm 'install' '--no-audit' '--no-fund'
        if ($LASTEXITCODE -ne 0) { throw 'npm install a échoué' }
    }
    finally { Pop-Location }

    # -------------------------------------------------------- Les 3 services
    Etape 'Démarrage'

    if (Port-Ouvert 8000) {
        Note 'API Laravel      : déjà en route sur le port 8000'
    } else {
        Start-Process -FilePath $outils.Php -ArgumentList 'artisan','serve','--port=8000' -WorkingDirectory $backend
        Note 'API Laravel      : port 8000'
    }

    if (Port-Ouvert 8080) {
        Note 'Serveur Reverb   : déjà en route sur le port 8080'
    } else {
        Start-Process -FilePath $outils.Php -ArgumentList 'artisan','reverb:start' -WorkingDirectory $backend
        Note 'Serveur Reverb   : port 8080'
    }

    if (Port-Ouvert 5173) {
        Note 'Espace admin     : déjà en route sur le port 5173'
    } else {
        Start-Process -FilePath $outils.Npm -ArgumentList 'run','dev' -WorkingDirectory $web
        Note 'Espace admin     : port 5173'
    }

    Write-Host ""
    Write-Host -NoNewline '  En attente de l''API'
    $prete = $false
    foreach ($essai in 1..60) {
        Start-Sleep -Milliseconds 500
        Write-Host -NoNewline '.'
        try {
            Invoke-WebRequest -Uri 'http://127.0.0.1:8000' -UseBasicParsing -TimeoutSec 2 | Out-Null
            $prete = $true
            break
        } catch {
            # Pas encore : on retente.
        }
    }
    Write-Host ""

    if (-not $prete) {
        throw "l'API n'a pas répondu. Regardez la fenêtre « php artisan serve »."
    }
    Bien 'API prête'
    Start-Process 'http://localhost:5173'

    # ---------------------------------------------------------------- Mobile
    # Le mobile vient en dernier, et son echec ne doit pas emporter le reste :
    # l'espace d'administration tourne deja, autant qu'il reste utilisable.
    Etape 'Application mobile'
    $mobileLance = $false
    try {
        $flutter = Resoudre-Flutter -Racine $racine -Installer

        Push-Location $mobile
        try {
            & $flutter pub get
            if ($LASTEXITCODE -ne 0) { throw 'flutter pub get a échoué' }
        }
        finally { Pop-Location }

        $navigateur = Resoudre-Navigateur
        if ($navigateur) { Note "Chrome absent — l'application s'ouvrira dans Edge." }

        $cible = Choisir-Cible $flutter
        Note "Cible : $($cible.Nom)"
        Note 'La compilation prend une à deux minutes ; une fenêtre lui est réservée.'

        $commande = "Set-Location '$mobile'; & '$flutter' run -d $($cible.Id)"
        Start-Process -FilePath 'powershell' `
                      -ArgumentList '-NoExit','-NoProfile','-ExecutionPolicy','Bypass','-Command',$commande `
                      -WorkingDirectory $mobile
        $mobileLance = $true
    }
    catch {
        Write-Host ""
        Alerte "L'application mobile n'a pas pu démarrer : $($_.Exception.Message)"
        Note   'Le reste fonctionne : vous pouvez utiliser l''espace d''administration.'
    }

    # -------------------------------------------------------- Le mot de la fin
    Write-Host ""
    Write-Host "  Tout tourne." -ForegroundColor Green
    Write-Host ""
    Write-Host "  Espace admin   http://localhost:5173" -ForegroundColor Yellow
    Write-Host "                 admin@onele.test / password        (direction)"
    Write-Host "                 fatou.kone@onele.test / password   (RH)"
    Write-Host ""
    if ($mobileLance) {
        Write-Host "  Application mobile — dans sa propre fenêtre" -ForegroundColor Yellow
        Write-Host "                 moussa.ndiaye@onele.test / password"
        Write-Host ""
    }
    Write-Host "  Fermez les fenêtres ouvertes pour tout arrêter." -ForegroundColor DarkGray
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "  Échec : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
