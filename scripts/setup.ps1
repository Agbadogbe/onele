#Requires -Version 5.1
<#
    Installation complete d'Onele sur Windows.

    Tout ce qui touche a la base et au fichier .env est delegue a
    `php artisan onele:installer` : la logique n'existe qu'une fois, partagee
    avec le script Unix, et il n'y a donc pas deux comportements possibles.
#>

$ErrorActionPreference = 'Stop'
$racine = Split-Path -Parent $PSScriptRoot

function Etape([string]$texte) { Write-Host "`n== $texte" -ForegroundColor Cyan }
function Bien([string]$texte)  { Write-Host "   $texte" -ForegroundColor Green }
function Note([string]$texte)  { Write-Host "   $texte" -ForegroundColor DarkGray }

function Trouver([string]$commande) {
    return [bool](Get-Command $commande -ErrorAction SilentlyContinue)
}

function Arreter([string]$manquant, [string]$ou) {
    Write-Host ""
    Write-Host "  $manquant est introuvable." -ForegroundColor Red
    Write-Host "  Installez-le ici : $ou" -ForegroundColor Red
    Write-Host "  Puis rouvrez un terminal (le PATH n'est lu qu'au demarrage) et relancez." -ForegroundColor Red
    Write-Host ""
    exit 1
}

# Un seul filet pour tout le script : sans lui, `powershell -File` peut rendre
# un code de sortie nul apres une erreur, et le .bat croirait a une reussite.
try {

    Write-Host ""
    Write-Host "  Onélé — installation" -ForegroundColor White
    Write-Host "  --------------------" -ForegroundColor DarkGray

    # ------------------------------------------------------------ Prerequis
    Etape 'Vérification des outils'

    if (-not (Trouver 'php'))      { Arreter 'PHP'      'https://windows.php.net/download (8.3 ou plus)' }
    if (-not (Trouver 'composer')) { Arreter 'Composer' 'https://getcomposer.org/download' }
    if (-not (Trouver 'npm'))      { Arreter 'Node.js'  'https://nodejs.org (version 20 ou plus)' }

    # Guillemets simples cote PHP, doubles cote PowerShell : PowerShell 5.1
    # mange les guillemets doubles imbriques quand il appelle un programme natif.
    $versionPhp = (& php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    if ([version]$versionPhp -lt [version]'8.3') {
        Write-Host ""
        Write-Host "  PHP $versionPhp est trop ancien : il en faut 8.3 au minimum." -ForegroundColor Red
        Write-Host ""
        exit 1
    }
    Bien "PHP $versionPhp"

    # `pdo_sqlite` est livre active dans les paquets officiels Windows, mais une
    # installation maison peut l'avoir commente dans php.ini : mieux vaut le dire
    # maintenant que de laisser la migration echouer trois etapes plus loin.
    & php -r "exit(extension_loaded('pdo_sqlite') ? 0 : 1);"
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "  L'extension pdo_sqlite est désactivée." -ForegroundColor Red
        Write-Host "  Ouvrez votre php.ini et décommentez la ligne : extension=pdo_sqlite" -ForegroundColor Red
        Write-Host ""
        exit 1
    }
    Bien 'Extension pdo_sqlite active'
    Bien "Node $((& node -v).TrimStart('v'))"

    $flutter = Trouver 'flutter'
    if ($flutter) { Bien 'Flutter détecté' } else { Note 'Flutter absent — le mobile sera ignoré' }

    # -------------------------------------------------------------- Backend
    Etape 'API Laravel'
    Push-Location (Join-Path $racine 'backend')
    try {
        & composer install --no-interaction --prefer-dist
        if ($LASTEXITCODE -ne 0) { throw 'composer install a échoué' }

        & php artisan onele:installer
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

        & npm install --no-audit --no-fund
        if ($LASTEXITCODE -ne 0) { throw 'npm install a échoué' }
    }
    finally { Pop-Location }

    # --------------------------------------------------------------- Mobile
    if ($flutter) {
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
