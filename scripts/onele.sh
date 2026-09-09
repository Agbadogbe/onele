#!/usr/bin/env bash
# Onélé, d'un seul geste : installe ce qui manque, puis démarre l'API, le
# serveur temps réel, l'espace d'administration et l'application mobile.
# Ctrl-C arrête l'ensemble.
set -euo pipefail

racine="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
port_mobile=8090

etape() { printf '\n\033[36m== %s\033[0m\n' "$1"; }
bien()  { printf '   \033[32m%s\033[0m\n' "$1"; }
note()  { printf '   \033[90m%s\033[0m\n' "$1"; }

# L'adresse de cette machine sur son réseau local : c'est par elle qu'un
# téléphone joint l'application et l'API.
adresse_locale() {
  local ip=''
  if command -v ipconfig >/dev/null 2>&1; then
    for carte in en0 en1 en2; do
      ip="$(ipconfig getifaddr "$carte" 2>/dev/null || true)"
      [ -n "$ip" ] && { printf '%s' "$ip"; return 0; }
    done
  fi
  if command -v ip >/dev/null 2>&1; then
    ip="$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}' || true)"
    [ -n "$ip" ] && { printf '%s' "$ip"; return 0; }
  fi
  ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  printf '%s' "$ip"
}

ouvrir() {
  if command -v open >/dev/null 2>&1; then open "$1" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$1" >/dev/null 2>&1 || true
  fi
}

port_ouvert() { curl -fsS -o /dev/null --max-time 2 "http://127.0.0.1:$1" 2>/dev/null; }

# ------------------------------------------------------------- Installation
"$racine/scripts/setup.sh"

# ------------------------------------------------------------- Les services
printf '\n  Onélé — démarrage\n'
printf '\033[90m  -----------------\033[0m\n'

pids=()
# Un seul piège pour tous les enfants : fermer le terminal ne doit pas laisser
# quatre serveurs orphelins derrière soi.
nettoyer() {
  printf '\n  Arrêt…\n'
  for pid in "${pids[@]:-}"; do kill "$pid" 2>/dev/null || true; done
  wait 2>/dev/null || true
  exit 0
}
trap nettoyer INT TERM

# --host=0.0.0.0 plutôt que la boucle locale : sans cela un téléphone du réseau
# ne verrait pas l'API.
(cd "$racine/backend" && php artisan serve --host=0.0.0.0 --port=8000) & pids+=($!)
note 'API Laravel      : port 8000'
(cd "$racine/backend" && php artisan reverb:start)                    & pids+=($!)
note 'Serveur Reverb   : port 8080'
(cd "$racine/web" && npm run dev)                                     & pids+=($!)
note 'Espace admin     : port 5173'

mobile_lance=0
if command -v flutter >/dev/null 2>&1; then
  # Servie sur toutes les interfaces plutôt que dans un navigateur : un
  # téléphone du réseau local y accède, et l'application déduit seule où
  # joindre l'API — c'est l'hôte qui lui a servi la page.
  (cd "$racine/mobile" && flutter run -d web-server \
      --web-hostname=0.0.0.0 --web-port="$port_mobile" > "$racine/mobile/.onele-web.log" 2>&1) & pids+=($!)
  note "Application mobile : port $port_mobile"
  mobile_lance=1
fi

# ----------------------------------------------------------- On attend l'API
printf '\n  Démarrage'
prete=0
for _ in $(seq 1 60); do
  sleep 0.5
  printf '.'
  if port_ouvert 8000; then prete=1; break; fi
done
printf '\n'
[ "$prete" = "1" ] && bien 'API prête' || printf '\033[33m  L'"'"'API n'"'"'a pas répondu ; regardez les journaux ci-dessus.\033[0m\n'
ouvrir 'http://localhost:5173'

# ------------------------------------------------- Puis la compilation mobile
mobile_prete=0
if [ "$mobile_lance" = "1" ]; then
  printf '  Compilation de l'"'"'application mobile'
  for i in $(seq 1 120); do
    sleep 2
    [ $((i % 3)) -eq 0 ] && printf '.'
    if port_ouvert "$port_mobile"; then mobile_prete=1; break; fi
  done
  printf '\n'
  if [ "$mobile_prete" = "1" ]; then
    bien 'Application mobile prête'
  else
    printf '\033[33m   La compilation prend plus longtemps que prévu ; voyez mobile/.onele-web.log\033[0m\n'
  fi
fi

# ----------------------------------------------------------- Le mot de la fin
ip="$(adresse_locale)"
printf '\n\033[32m  Tout tourne.\033[0m\n\n'
printf '  Espace admin         \033[33mhttp://localhost:5173\033[0m\n'
printf '                       admin@onele.test / password        (direction)\n'
printf '                       fatou.kone@onele.test / password   (RH)\n\n'
if [ "$mobile_prete" = "1" ]; then
  printf '  Application mobile   \033[33mhttp://localhost:%s\033[0m\n' "$port_mobile"
  printf '                       moussa.ndiaye@onele.test / password\n\n'
  if [ -n "$ip" ]; then
    printf '\033[36m  Sur un vrai téléphone\033[0m\n'
    printf '\033[90m      Même Wi-Fi que cette machine, puis dans le navigateur du téléphone :\033[0m\n'
    printf '      \033[33mhttp://%s:%s\033[0m\n' "$ip" "$port_mobile"
    printf '\033[90m      Aucune installation : l'"'"'application s'"'"'adresse d'"'"'elle-même à cette machine.\033[0m\n\n'
  fi
fi
printf '\033[90m  Ctrl-C pour tout arrêter.\033[0m\n\n'

wait
