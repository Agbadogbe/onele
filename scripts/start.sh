#!/usr/bin/env bash
# Démarre les trois services d'Onélé. Ctrl-C arrête tout d'un coup.
set -euo pipefail

racine="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
note() { printf '  \033[90m%s\033[0m\n' "$1"; }

# ------------------------------------------- L'installation a-t-elle eu lieu ?
manques=()
[ -d "$racine/backend/vendor" ]   || manques+=('backend/vendor')
[ -f "$racine/backend/.env" ]     || manques+=('backend/.env')
[ -d "$racine/web/node_modules" ] || manques+=('web/node_modules')

if [ "${#manques[@]}" -gt 0 ]; then
  printf '\n\033[31m  Il manque : %s\n  Lancez d'"'"'abord ./scripts/setup.sh\033[0m\n\n' "${manques[*]}"
  exit 1
fi

printf '\n  Onélé — démarrage\n'
printf '\033[90m  -----------------\033[0m\n'

pids=()
# Un seul piège pour tous les enfants : fermer le terminal ne doit pas laisser
# trois serveurs orphelins derrière soi.
nettoyer() {
  printf '\n  Arrêt…\n'
  for pid in "${pids[@]:-}"; do kill "$pid" 2>/dev/null || true; done
  wait 2>/dev/null || true
  exit 0
}
trap nettoyer INT TERM

(cd "$racine/backend" && php artisan serve --host=0.0.0.0 --port=8000) & pids+=($!)
note 'API Laravel      : port 8000'
(cd "$racine/backend" && php artisan reverb:start)        & pids+=($!)
note 'Serveur Reverb   : port 8080'
(cd "$racine/web" && npm run dev)                         & pids+=($!)
note 'Espace admin     : port 5173'

# --------------------------------------------------------------- On attend l'API
printf '\n  Démarrage'
prete=0
for _ in $(seq 1 40); do
  sleep 0.5
  printf '.'
  if curl -fsS -o /dev/null --max-time 2 http://127.0.0.1:8000 2>/dev/null; then prete=1; break; fi
done
printf '\n'

if [ "$prete" = "0" ]; then
  printf '\n\033[33m  L'"'"'API n'"'"'a pas répondu ; regardez les journaux ci-dessus.\033[0m\n\n'
fi

printf '\n\033[32m  Tout tourne.\033[0m\n\n'
printf '  Espace admin   \033[33mhttp://localhost:5173\033[0m\n'
printf '                 admin@onele.test / password\n\n'
printf '  Application mobile, dans un autre terminal :\n'
printf '\033[33m      cd mobile && flutter run\033[0m\n'
printf '                 moussa.ndiaye@onele.test / password\n\n'
printf '\033[90m  Ctrl-C pour tout arrêter.\033[0m\n\n'

wait
