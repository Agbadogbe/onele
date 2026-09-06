#Requires -Version 5.1
<#
    Demarre les trois services d'Onele, chacun dans sa propre fenetre pour que
    ses journaux restent lisibles. Fermer une fenetre arrete le service.
#>

$ErrorActionPreference = 'Stop'
$racine  = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $racine 'backend'
$web     = Join-Path $racine 'web'
. (Join-Path $PSScriptRoot 'outils.ps1')

try {

    # ------------------------------------- L'installation a-t-elle eu lieu ?
    $manques = @()
    if (-not (Test-Path (Join-Path $backend 'vendor')))   { $manques += 'backend/vendor' }
    if (-not (Test-Path (Join-Path $backend '.env')))     { $manques += 'backend/.env' }
    if (-not (Test-Path (Join-Path $web 'node_modules'))) { $manques += 'web/node_modules' }

    if ($manques.Count -gt 0) {
        Write-Host ""
        Write-Host "  Il manque : $($manques -join ', ')" -ForegroundColor Red
        Write-Host "  Lancez d'abord .\setup.bat" -ForegroundColor Red
        Write-Host ""
        exit 1
    }

    # Ce que l'installation a retenu ; a defaut, on redetecte, mais sans jamais
    # rien installer ici : demarrer n'est pas le moment de telecharger PHP.
    $outils = Lire-Outils $racine
    if (-not $outils -or -not (Test-Path $outils.Php) -or -not (Test-Path $outils.Npm)) {
        $outils = Resoudre-Outils -Racine $racine
    }
    if ($outils.PhpLocal) { $env:PHPRC = $outils.DossierPhp }

    Write-Host ""
    Write-Host "  Onélé — démarrage" -ForegroundColor White
    Write-Host "  -----------------" -ForegroundColor DarkGray

    # ------------------------------------------------------ Les trois services
    Start-Process -FilePath $outils.Php -ArgumentList 'artisan','serve','--port=8000' -WorkingDirectory $backend
    Note 'API Laravel      : port 8000'

    Start-Process -FilePath $outils.Php -ArgumentList 'artisan','reverb:start' -WorkingDirectory $backend
    Note 'Serveur Reverb   : port 8080'

    Start-Process -FilePath $outils.Npm -ArgumentList 'run','dev' -WorkingDirectory $web
    Note 'Espace admin     : port 5173'

    # ----------------------------------------------------------- On attend l'API
    Write-Host ""
    Write-Host -NoNewline '  Démarrage'
    $prete = $false
    foreach ($essai in 1..40) {
        Start-Sleep -Milliseconds 500
        Write-Host -NoNewline '.'
        try {
            Invoke-WebRequest -Uri 'http://127.0.0.1:8000' -UseBasicParsing -TimeoutSec 2 | Out-Null
            $prete = $true
            break
        } catch {
            # Le serveur n'ecoute pas encore : on retente.
        }
    }
    Write-Host ""

    if (-not $prete) {
        Write-Host ""
        Write-Host "  L'API n'a pas répondu. Regardez la fenêtre « php artisan serve »." -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }

    # -------------------------------------------------------- Le mot de la fin
    Write-Host ""
    Write-Host "  Tout tourne." -ForegroundColor Green
    Write-Host ""
    Write-Host "  Espace admin   http://localhost:5173" -ForegroundColor Yellow
    Write-Host "                 admin@onele.test / password"
    Write-Host ""
    Write-Host "  Application mobile, dans un quatrième terminal :" -ForegroundColor White
    Write-Host "      cd mobile" -ForegroundColor Yellow
    Write-Host "      flutter run -d chrome" -ForegroundColor Yellow
    Write-Host "                 moussa.ndiaye@onele.test / password"
    Write-Host ""
    Write-Host "  Fermez les fenêtres ouvertes pour tout arrêter." -ForegroundColor DarkGray
    Write-Host ""

    Start-Process 'http://localhost:5173'
}
catch {
    Write-Host ""
    Write-Host "  Échec : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
