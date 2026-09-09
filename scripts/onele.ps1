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
$PORT_MOBILE = 8090
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
        # --host=0.0.0.0 plutot que la boucle locale : sans cela un telephone du
        # reseau ne verrait pas l'API. Windows demandera peut-etre l'autorisation
        # du pare-feu au premier lancement.
        Start-Process -FilePath $outils.Php -ArgumentList 'artisan','serve','--host=0.0.0.0','--port=8000' -WorkingDirectory $backend
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
    $mobilePrete = $false
    $adresseLocale = $null
    try {
        $flutter = Resoudre-Flutter -Racine $racine -Installer

        Push-Location $mobile
        try {
            & $flutter pub get
            if ($LASTEXITCODE -ne 0) { throw 'flutter pub get a échoué' }
        }
        finally { Pop-Location }

        $cible = Choisir-Cible $flutter
        Note "Cible : $($cible.Nom)"
        Note 'La compilation prend une à deux minutes ; une fenêtre lui est réservée.'

        if ($cible.Id -eq 'chrome') {
            # Plutot que de lancer Chrome, on sert l'application sur toutes les
            # interfaces : le PC l'ouvre comme avant, et un telephone du reseau
            # local y accede par la meme adresse. L'application deduit alors
            # seule ou joindre l'API — c'est l'hote qui lui a servi la page.
            $arguments = "run -d web-server --web-hostname=0.0.0.0 --web-port=$PORT_MOBILE"
        } else {
            $arguments = "run -d $($cible.Id)"
        }
        $commande = "Set-Location '$mobile'; & '$flutter' $arguments"
        Start-Process -FilePath 'powershell' `
                      -ArgumentList '-NoExit','-NoProfile','-ExecutionPolicy','Bypass','-Command',$commande `
                      -WorkingDirectory $mobile
        $mobileLance = $true

        if ($cible.Id -eq 'chrome') {
            Write-Host ""
            Write-Host -NoNewline '  Compilation de l''application mobile'
            foreach ($essai in 1..360) {
                Start-Sleep -Seconds 1
                if ($essai % 3 -eq 0) { Write-Host -NoNewline '.' }
                if (Port-Ouvert $PORT_MOBILE) { $mobilePrete = $true; break }
            }
            Write-Host ""
            if ($mobilePrete) {
                Bien 'Application mobile prête'
                Start-Process "http://localhost:$PORT_MOBILE"
                $adresseLocale = Adresse-Locale
            } else {
                Alerte 'La compilation prend plus longtemps que prévu ; regardez sa fenêtre.'
            }
        }
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
    if ($mobilePrete) {
        Write-Host "  Application mobile   http://localhost:$PORT_MOBILE" -ForegroundColor Yellow
        Write-Host "                 moussa.ndiaye@onele.test / password"
        Write-Host ""
        if ($adresseLocale) {
            Write-Host "  Sur un vrai téléphone" -ForegroundColor Cyan
            Write-Host "      Même Wi-Fi que ce PC, puis dans le navigateur du téléphone :" -ForegroundColor DarkGray
            Write-Host "      http://${adresseLocale}:$PORT_MOBILE" -ForegroundColor Yellow
            Write-Host "      Aucune installation : l'application s'adresse d'elle-même à ce PC." -ForegroundColor DarkGray
            Write-Host ""

            $ports = @(8000, 8080, $PORT_MOBILE)
            switch (Regle-PareFeu $ports) {
                'posee' { Note 'Règle de pare-feu ajoutée pour les réseaux privés.' }
                'adroits' {
                    Write-Host "      Si le téléphone n'y arrive pas, c'est le pare-feu." -ForegroundColor DarkGray
                    Write-Host "      Ouvrez PowerShell en administrateur et collez :" -ForegroundColor DarkGray
                    Write-Host "      $(Commande-PareFeu $ports)" -ForegroundColor DarkGray
                    Write-Host ""
                }
                default { }
            }
        }
    } elseif ($mobileLance) {
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
