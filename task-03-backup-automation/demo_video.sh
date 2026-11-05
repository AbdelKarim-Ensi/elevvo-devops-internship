#!/usr/bin/env bash
# Démo vidéo Tâche 3 : Entrée pour passer à l'étape suivante
export LC_ALL=C
cd "$(dirname "$0")"
DIR="$PWD"

step() {
  printf '\n\033[1;36m%s\033[0m\n\n' "$1"
  read -r -s -p "   (Entrée pour continuer)" _; echo; echo
}

step "1) Contenu de la tâche"
ls -la

step "2) Hygiène des secrets : .env ignoré par Git, seul .env.example est suivi"
ls -a | grep -E '^\.env'
git check-ignore -v .env
git ls-files | grep -E '\.env'
git ls-files | grep -E '\.env$' && echo "PROBLEME" || echo "OK: aucun .env suivi par Git"

step "3) Aucun secret en dur : tout vient de l'environnement (.env)"
grep -n -E 'source|\.env|WEBHOOK_URL' backup.sh | head -n 8

step "4) Exécution manuelle : archive compressée + rotation"
bash demo.sh 2>&1 | tail -n 20

step "5) Résultat : archives .tar.gz créées"
ls -lh backups/ 2>/dev/null || find . -name '*.tar.gz' -printf '%p  %s octets\n'

step "6) Planification cron : ajout d'une ligne (toutes les minutes pour la démo)"
( crontab -l 2>/dev/null | grep -v 'ELEVVO_DEMO'; echo "* * * * * cd $DIR && bash backup.sh >> $DIR/cron_demo.log 2>&1 # ELEVVO_DEMO" ) | crontab -
crontab -l | grep ELEVVO_DEMO
systemctl is-active cron

step "7) Exécution automatique par cron, sans intervention (max 70 s)"
BEFORE=$(find . -name '*.tar.gz' | wc -l)
for i in $(seq 1 70); do
  NOW=$(find . -name '*.tar.gz' | wc -l)
  [ "$NOW" -gt "$BEFORE" ] && break
  sleep 1; printf '.'
done; echo
date '+Heure actuelle : %H:%M:%S'
ls -lt --time-style=+%H:%M:%S $(find . -name '*.tar.gz') | head -n 3
tail -n 5 cron_demo.log 2>/dev/null

step "8) Retrait de la ligne de démo et état final de Git"
crontab -l 2>/dev/null | grep -v 'ELEVVO_DEMO' | crontab -
crontab -l 2>/dev/null | grep -c ELEVVO_DEMO | sed 's/^0$/OK: ligne de démo retirée/'
git status -sb
printf '\n\033[1;32mFin de la démo.\033[0m\n'
