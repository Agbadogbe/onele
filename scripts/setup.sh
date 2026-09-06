#!/usr/bin/env bash
# Installation complète d'Onélé sur macOS et Linux.
#
# Tout ce qui touche à la base et au fichier .env est délégué à
# `php artisan onele:installer` : la logique n'existe qu'une fois, partagée
# avec le script Windows, et il n'y a donc pas deux comportements possibles.
set -euo pipefail

racine="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

etape() { printf '\n\033[36m== %s\033[0m\n' "$1"; }
bien()  { printf '   \033[32m%s\033[0m\n' "$1"; }
note()  { printf '   \033[90m%s\033[0m\n' "$1"; }
arreter() {
  printf '\n\033[31m  %s est introuvable.\n  Installez-le ici : %s\033[0m\n\n' "$1" "$2"
  exit 1
}

printf '\n  Onélé — installation\n'
printf '\033[90m  --------------------\033[0m\n'

# ---------------------------------------------------------------- Prérequis
etape 'Vérification des outils'

command -v php      >/dev/null || arreter 'PHP'      'https://www.php.net/downloads (8.3 ou plus)'
command -v composer >/dev/null || arreter 'Composer' 'https://getcomposer.org/download'
command -v npm      >/dev/null || arreter 'Node.js'  'https://nodejs.org (version 20 ou plus)'

version_php="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
if [ "$(printf '%s\n8.3\n' "$version_php" | sort -V | head -1)" != "8.3" ]; then
  printf '\n\033[31m  PHP %s est trop ancien : il en faut 8.3 au minimum.\033[0m\n\n' "$version_php"
  exit 1
fi
bien "PHP $version_php"

if ! php -r 'exit(extension_loaded("pdo_sqlite") ? 0 : 1);'; then
  printf '\n\033[31m  L'"'"'extension pdo_sqlite est désactivée.\n  Activez-la dans votre php.ini : extension=pdo_sqlite\033[0m\n\n'
  exit 1
fi
bien 'Extension pdo_sqlite active'
bien "Node $(node -v | tr -d v)"

if command -v flutter >/dev/null; then
  flutter_present=1
  bien 'Flutter détecté'
else
  flutter_present=0
  note 'Flutter absent — le mobile sera ignoré'
fi

# ------------------------------------------------------------------ Backend
etape 'API Laravel'
(cd "$racine/backend" && composer install --no-interaction --prefer-dist && php artisan onele:installer)

# ---------------------------------------------------------------------- Web
etape "Espace d'administration"
cd "$racine/web"
if [ ! -f .env ]; then
  cp .env.example .env
  bien 'Création du fichier web/.env'
fi
npm install --no-audit --no-fund

# ------------------------------------------------------------------- Mobile
if [ "$flutter_present" = "1" ]; then
  etape 'Application mobile'
  (cd "$racine/mobile" && flutter pub get)
fi

# --------------------------------------------------------- Le mot de la fin
printf '\n\033[32m  Installation terminée.\033[0m\n\n'
printf '  Pour tout démarrer :\n'
printf '\033[33m      ./scripts/start.sh\033[0m\n\n'
