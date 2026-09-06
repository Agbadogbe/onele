#!/usr/bin/env bash
# Onélé, d'un seul geste : installe ce qui manque, puis démarre tout.
# Ctrl-C arrête l'ensemble.
set -euo pipefail

racine="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$racine/scripts/setup.sh"
exec "$racine/scripts/start.sh"
