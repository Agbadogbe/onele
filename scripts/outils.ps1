#Requires -Version 5.1
<#
    Resolution des outils dont Onele a besoin, et installation automatique de
    ceux qui manquent.

    Le principe : ne rien demander, et ne rien toucher hors du depot. Ce qui
    manque est depose dans tools\, ou il ne genera aucune autre installation de
    la machine et disparaitra avec le dossier du projet. Aucun droit
    administrateur, aucune modification du PATH.
#>

$PHP_BRANCHE  = '8.4'
$PHP_MINIMUM  = [version]'8.3'
$PHP_REPLI    = 'php-8.4.25-nts-Win32-vs17-x64.zip'
$NODE_MINIMUM = 20
$NODE_REPLI   = 'v24.20.0'

# ------------------------------------------------------------------ Affichage

function Etape([string]$texte)  { Write-Host "`n== $texte" -ForegroundColor Cyan }
function Bien([string]$texte)   { Write-Host "   $texte" -ForegroundColor Green }
function Note([string]$texte)   { Write-Host "   $texte" -ForegroundColor DarkGray }
function Alerte([string]$texte) { Write-Host "   $texte" -ForegroundColor Yellow }

# ---------------------------------------------------------------- Utilitaires

function Preparer-Reseau {
    # PowerShell 5.1 negocie encore TLS 1.0 par defaut sur certaines machines :
    # sans cette ligne, les telechargements echouent sur une erreur de canal SSL.
    try {
        [Net.ServicePointManager]::SecurityProtocol =
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch {
        # Runtime trop ancien pour cette constante : on continue avec le defaut.
    }
    # Invoke-WebRequest est dix fois plus lent quand il dessine sa barre.
    $global:ProgressPreference = 'SilentlyContinue'
}

function Telecharger([string[]]$adresses, [string]$vers) {
    Preparer-Reseau
    $partiel = "$vers.partiel"
    $derniere = $null
    foreach ($adresse in $adresses) {
        try {
            Invoke-WebRequest -Uri $adresse -OutFile $partiel -UseBasicParsing
            Move-Item -Force -Path $partiel -Destination $vers
            return
        } catch {
            $derniere = $_.Exception.Message
            Remove-Item -Force -ErrorAction SilentlyContinue $partiel
        }
    }
    throw "telechargement impossible ($($adresses[0])) : $derniere"
}

function Dezipper([string]$archive, [string]$vers) {
    if (Test-Path $vers) { Remove-Item -Recurse -Force $vers }
    New-Item -ItemType Directory -Force -Path $vers | Out-Null
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($archive, $vers)
    } catch {
        # Repli sur l'applet, plus lente mais toujours disponible.
        Expand-Archive -Path $archive -DestinationPath $vers -Force
    }
}

function Memes-Chemins([string]$a, [string]$b) {
    if (-not $a -or -not $b) { return $false }
    try {
        $a = [System.IO.Path]::GetFullPath($a)
        $b = [System.IO.Path]::GetFullPath($b)
    } catch {
        return $false
    }
    return [string]::Equals($a, $b, [StringComparison]::OrdinalIgnoreCase)
}

# ------------------------------------------------------------------------ PHP

function Sonder-Php([string]$exe) {
    if (-not $exe) { return $null }
    # Un marqueur plutot que la sortie brute : certaines installations font
    # preceder chaque reponse d'un avertissement de demarrage.
    $code = "echo 'SONDE=', PHP_MAJOR_VERSION, '.', PHP_MINOR_VERSION, ',', (int) extension_loaded('pdo_sqlite');"
    try {
        $sortie = (& $exe -d display_errors=0 -d display_startup_errors=0 -r $code | Out-String)
    } catch {
        return $null
    }
    if ($sortie -notmatch 'SONDE=(\d+)\.(\d+),(\d)') { return $null }
    return [pscustomobject]@{
        Chemin  = $exe
        Version = [version]"$($Matches[1]).$($Matches[2])"
        Sqlite  = ($Matches[3] -eq '1')
    }
}

function Php-Convient($sonde) {
    return [bool]($sonde -and $sonde.Version -ge $PHP_MINIMUM -and $sonde.Sqlite)
}

function Ecrire-PhpIni([string]$dossier) {
    # Un php.ini ecrit par nous plutot que php.ini-development decommente a la
    # main : le resultat ne depend alors d'aucune edition manuelle.
    $lignes = @(
        '; Genere par l''installation d''Onele.',
        '; Ce PHP appartient au depot et n''affecte rien d''autre sur la machine.',
        "extension_dir = `"$(Join-Path $dossier 'ext')`"",
        'extension=curl',
        'extension=fileinfo',
        'extension=mbstring',
        'extension=openssl',
        'extension=pdo_sqlite',
        'extension=sqlite3',
        'extension=zip',
        'memory_limit = 512M'
    )
    Set-Content -Path (Join-Path $dossier 'php.ini') -Value $lignes -Encoding ASCII
}

function Installer-Php([string]$dossier) {
    Preparer-Reseau
    $nom = $null
    try {
        $catalogue = Invoke-RestMethod -Uri 'https://windows.php.net/downloads/releases/releases.json' -UseBasicParsing -TimeoutSec 30
        $branche = $catalogue.$PHP_BRANCHE
        if ($branche) {
            foreach ($entree in $branche.PSObject.Properties) {
                if ($entree.Name -match '^nts-vs\d+-x64$' -and $entree.Value.zip.path) {
                    $nom = $entree.Value.zip.path
                    break
                }
            }
        }
    } catch {
        # Catalogue injoignable : on retombe sur une version connue.
    }
    if (-not $nom) { $nom = $PHP_REPLI }

    $zip = Join-Path $env:TEMP $nom
    Note "Téléchargement de PHP ($nom, environ 33 Mo)…"
    Telecharger @(
        "https://windows.php.net/downloads/releases/$nom",
        "https://windows.php.net/downloads/releases/archives/$nom"
    ) $zip

    Note 'Décompression…'
    Dezipper $zip $dossier
    Remove-Item -Force -ErrorAction SilentlyContinue $zip
    Ecrire-PhpIni $dossier
}

# ----------------------------------------------------------------------- Node

function Sonder-Node([string]$exe) {
    if (-not $exe) { return $null }
    try {
        $sortie = (& $exe -v | Out-String)
    } catch {
        return $null
    }
    if ($sortie -notmatch 'v?(\d+)\.(\d+)\.(\d+)') { return $null }
    return [pscustomobject]@{
        Chemin  = $exe
        Version = [version]"$($Matches[1]).$($Matches[2]).$($Matches[3])"
    }
}

function Node-Convient($sonde) {
    return [bool]($sonde -and $sonde.Version.Major -ge $NODE_MINIMUM)
}

function Installer-Node([string]$dossier) {
    Preparer-Reseau
    $version = $null
    try {
        $index = Invoke-RestMethod -Uri 'https://nodejs.org/dist/index.json' -UseBasicParsing -TimeoutSec 30
        foreach ($entree in $index) {
            if ($entree.lts -and ($entree.files -contains 'win-x64-zip')) {
                $version = $entree.version
                break
            }
        }
    } catch {
        # Index injoignable : on retombe sur une version connue.
    }
    if (-not $version) { $version = $NODE_REPLI }

    $nom = "node-$version-win-x64"
    $zip = Join-Path $env:TEMP "$nom.zip"
    Note "Téléchargement de Node $version (environ 36 Mo)…"
    Telecharger @("https://nodejs.org/dist/$version/$nom.zip") $zip

    Note 'Décompression…'
    # L'archive Node porte un dossier racine, contrairement a celle de PHP :
    # on decompresse a cote puis on remonte son contenu.
    $intermediaire = Join-Path $env:TEMP ("onele-node-" + [guid]::NewGuid().ToString('N'))
    Dezipper $zip $intermediaire
    if (Test-Path $dossier) { Remove-Item -Recurse -Force $dossier }
    Move-Item -Path (Join-Path $intermediaire $nom) -Destination $dossier
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $intermediaire
    Remove-Item -Force -ErrorAction SilentlyContinue $zip
}

# ------------------------------------------------------------------- Composer

function Obtenir-ComposerPhar([string]$tools) {
    $phar = Join-Path $tools 'composer.phar'
    if (-not (Test-Path $phar)) {
        Note 'Téléchargement de Composer…'
        Telecharger @('https://getcomposer.org/download/latest-stable/composer.phar') $phar
    }
    return $phar
}

# ------------------------------------------------------------- La resolution

function Resoudre-Outils {
    param(
        [Parameter(Mandatory = $true)][string]$Racine,
        [switch]$Installer,
        # Demarrer n'a besoin que de PHP et de npm : exiger Composer ferait
        # echouer start.bat pour un outil qu'il n'utilise jamais.
        [switch]$AvecComposer
    )

    $tools = Join-Path $Racine 'tools'
    if ($Installer) { New-Item -ItemType Directory -Force -Path $tools | Out-Null }

    # ---------------------------------------------------------------- PHP
    $phpDossier = Join-Path $tools 'php'
    $phpLocal   = Join-Path $phpDossier 'php.exe'
    $sonde      = $null
    $phpEstLocal = $false

    $systeme = Get-Command 'php' -ErrorAction SilentlyContinue
    if ($systeme) {
        $candidat = Sonder-Php $systeme.Source
        if (Php-Convient $candidat) {
            $sonde = $candidat
        } elseif ($candidat -and -not $candidat.Sqlite) {
            Alerte "PHP $($candidat.Version) est installé sur la machine, mais sans pdo_sqlite."
        } elseif ($candidat) {
            Alerte "PHP $($candidat.Version) est installé sur la machine ; il en faut 8.3 au minimum."
        }
    }

    if (-not $sonde -and (Test-Path $phpLocal)) {
        $candidat = Sonder-Php $phpLocal
        if (Php-Convient $candidat) {
            $sonde = $candidat
            $phpEstLocal = $true
        }
    }

    if (-not $sonde) {
        if (-not $Installer) { throw 'PHP 8.3 est introuvable. Lancez d''abord .\setup.bat' }
        Note 'Onélé installe donc le sien dans tools\php — rien d''autre sur la machine n''est touché.'
        Installer-Php $phpDossier
        $sonde = Sonder-Php $phpLocal
        if (-not (Php-Convient $sonde)) {
            throw @'
le PHP installe dans tools\php ne demarre pas.

    C'est presque toujours la bibliotheque Visual C++ qui manque sur la machine.
    Installez-la ici, puis relancez setup.bat :
        https://aka.ms/vs/17/release/vc_redist.x64.exe
'@
        }
        $phpEstLocal = $true
    }

    $php = $sonde.Chemin
    if ($phpEstLocal) {
        # Un PHPRC herite d'une autre installation ferait lire le mauvais
        # php.ini a notre binaire : on impose le notre pour nos processus.
        $env:PHPRC = $phpDossier
        Bien "PHP $($sonde.Version) (fourni avec le projet)"
    } else {
        Bien "PHP $($sonde.Version)"
    }

    # --------------------------------------------------------------- Node
    $nodeDossier = Join-Path $tools 'node'
    $nodeLocal   = Join-Path $nodeDossier 'node.exe'
    $sondeNode   = $null
    $nodeEstLocal = $false

    $systeme = Get-Command 'node' -ErrorAction SilentlyContinue
    if ($systeme) {
        $candidat = Sonder-Node $systeme.Source
        if (Node-Convient $candidat) {
            $sondeNode = $candidat
        } elseif ($candidat) {
            Alerte "Node $($candidat.Version) est installé sur la machine ; il en faut 20 au minimum."
        }
    }

    if (-not $sondeNode -and (Test-Path $nodeLocal)) {
        $candidat = Sonder-Node $nodeLocal
        if (Node-Convient $candidat) {
            $sondeNode = $candidat
            $nodeEstLocal = $true
        }
    }

    if (-not $sondeNode) {
        if (-not $Installer) { throw 'Node 20 est introuvable. Lancez d''abord .\setup.bat' }
        Note 'Onélé installe donc le sien dans tools\node.'
        Installer-Node $nodeDossier
        $sondeNode = Sonder-Node $nodeLocal
        if (-not (Node-Convient $sondeNode)) { throw 'le Node installe dans tools\node ne demarre pas.' }
        $nodeEstLocal = $true
    }

    if ($nodeEstLocal) {
        $npm = Join-Path $nodeDossier 'npm.cmd'
        Bien "Node $($sondeNode.Version) (fourni avec le projet)"
    } else {
        # Certaines installations exposent npm en .ps1, que Start-Process ne
        # saurait pas lancer : on vise le .cmd en priorite.
        $commande = Get-Command 'npm.cmd' -ErrorAction SilentlyContinue
        if (-not $commande) { $commande = Get-Command 'npm' -ErrorAction SilentlyContinue }
        if (-not $commande) { throw 'npm est introuvable alors que node repond.' }
        $npm = $commande.Source
        Bien "Node $($sondeNode.Version)"
    }

    # ----------------------------------------------------------- Composer
    # Un composer du systeme s'appuie sur le PHP du systeme : des que nous
    # utilisons le notre, il faut passer par le phar pour rester coherent.
    $composerFichier = $null
    $composerPrefixe = @()
    if ($AvecComposer -and -not $phpEstLocal) {
        $commande = Get-Command 'composer' -ErrorAction SilentlyContinue
        if ($commande) {
            $composerFichier = $commande.Source
            Bien 'Composer'
        }
    }
    if ($AvecComposer -and -not $composerFichier) {
        if (-not $Installer -and -not (Test-Path (Join-Path $tools 'composer.phar'))) {
            throw 'Composer est introuvable. Lancez d''abord .\setup.bat'
        }
        $composerFichier = $php
        $composerPrefixe = @((Obtenir-ComposerPhar $tools))
        Bien 'Composer (fourni avec le projet)'
    }

    $flutter = [bool](Get-Command 'flutter' -ErrorAction SilentlyContinue)

    return [pscustomobject]@{
        Php             = $php
        PhpLocal        = $phpEstLocal
        DossierPhp      = $phpDossier
        Npm             = $npm
        ComposerFichier = $composerFichier
        ComposerPrefixe = $composerPrefixe
        Flutter         = $flutter
    }
}

function Enregistrer-Outils($Outils, [string]$Racine) {
    $fichier = Join-Path $Racine 'tools\outils.json'
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $fichier) | Out-Null
    $Outils | ConvertTo-Json | Set-Content -Path $fichier -Encoding UTF8
}

function Lire-Outils([string]$Racine) {
    $fichier = Join-Path $Racine 'tools\outils.json'
    if (-not (Test-Path $fichier)) { return $null }
    try {
        return (Get-Content -Path $fichier -Raw | ConvertFrom-Json)
    } catch {
        return $null
    }
}

# -------------------------------------------------------------------- Flutter

function Sonder-Flutter([string]$exe) {
    if (-not $exe -or -not (Test-Path $exe)) { return $null }
    try {
        $sortie = (& $exe --version --machine | Out-String)
    } catch {
        return $null
    }
    if ($sortie -notmatch '"frameworkVersion"\s*:\s*"([^"]+)"') { return $null }
    return [pscustomobject]@{ Chemin = $exe; Version = $Matches[1] }
}

function Adresse-Flutter {
    # Le catalogue officiel donne l'archive stable du moment ; a defaut, on
    # retombe sur une version connue.
    try {
        $catalogue = Invoke-RestMethod -Uri 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json' -UseBasicParsing -TimeoutSec 30
        $empreinte = $catalogue.current_release.stable
        foreach ($sortie in $catalogue.releases) {
            if ($sortie.hash -eq $empreinte -and $sortie.channel -eq 'stable') {
                return @{
                    Adresse = ($catalogue.base_url + '/' + $sortie.archive)
                    Version = $sortie.version
                }
            }
        }
    } catch {
        # Catalogue injoignable.
    }
    return @{
        Adresse = 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.47.2-stable.zip'
        Version = '3.47.2'
    }
}

function Installer-Flutter([string]$dossier) {
    Preparer-Reseau
    $choix = Adresse-Flutter
    Write-Host ""
    Alerte "Flutter $($choix.Version) va être téléchargé : environ 1,8 Go."
    Note   'C''est long — dix à trente minutes selon la connexion — mais une seule fois.'
    Note   'Comme le reste, il atterrit dans tools\ et ne touche rien sur la machine.'
    Write-Host ""

    $zip = Join-Path $env:TEMP 'flutter-windows.zip'
    Telecharger @($choix.Adresse) $zip

    Note 'Décompression (comptez quelques minutes)…'
    # L'archive porte un dossier « flutter » a sa racine : on le remonte.
    $intermediaire = Join-Path $env:TEMP ("onele-flutter-" + [guid]::NewGuid().ToString('N'))
    Dezipper $zip $intermediaire
    if (Test-Path $dossier) { Remove-Item -Recurse -Force $dossier }
    Move-Item -Path (Join-Path $intermediaire 'flutter') -Destination $dossier
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $intermediaire
    Remove-Item -Force -ErrorAction SilentlyContinue $zip
}

function Resoudre-Flutter {
    param(
        [Parameter(Mandatory = $true)][string]$Racine,
        [switch]$Installer
    )

    $dossier = Join-Path $Racine 'tools\flutter'
    $local   = Join-Path $dossier 'bin\flutter.bat'

    $systeme = Get-Command 'flutter' -ErrorAction SilentlyContinue
    if ($systeme) {
        $sonde = Sonder-Flutter $systeme.Source
        if ($sonde) { Bien "Flutter $($sonde.Version)"; return $sonde.Chemin }
    }

    if (Test-Path $local) {
        $sonde = Sonder-Flutter $local
        if ($sonde) { Bien "Flutter $($sonde.Version) (fourni avec le projet)"; return $sonde.Chemin }
    }

    if (-not $Installer) { return $null }

    # Flutter s'appuie sur git pour connaitre sa propre version : sans lui,
    # l'archive se decompresse mais aucune commande ne repond.
    if (-not (Get-Command 'git' -ErrorAction SilentlyContinue)) {
        throw @'
git est introuvable, et Flutter ne fonctionne pas sans lui.

    Installez-le ici, puis relancez :
        https://git-scm.com/download/win
'@
    }

    Installer-Flutter $dossier
    $sonde = Sonder-Flutter $local
    if (-not $sonde) { throw 'le Flutter installe dans tools\flutter ne repond pas.' }
    Bien "Flutter $($sonde.Version) (fourni avec le projet)"
    return $sonde.Chemin
}
