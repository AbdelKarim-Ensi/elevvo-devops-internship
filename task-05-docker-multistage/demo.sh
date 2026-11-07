#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"
step() { echo; echo "=== $1 ==="; }

step "1. Containers (no host port on the database)"
docker compose ps

step "2. Non-root user"
docker compose exec app whoami
docker compose exec app id

step "3. Image size"
docker images todo-app:latest

step "4. Backend network is private"
docker network inspect task-05-docker-multistage_backend --format 'internal={{.Internal}}'

step "5. App works and uses the database"
curl -s localhost:3000/health; echo
curl -s -X POST localhost:3000/todos -H 'Content-Type: application/json' -d '{"title":"Finish Task 5"}'; echo
curl -s localhost:3000/todos; echo

step "6. Database unreachable from the host"
nc -zv -w 3 localhost 5432 || echo "5432 closed on host: OK"

step "7. Database reachable from the app (private DNS)"
docker compose exec app node -e "require('net').connect(5432,'postgres-db').on('connect',()=>{console.log('postgres-db:5432 reachable');process.exit(0)}).on('error',e=>{console.log(e.message);process.exit(1)})"

step "8. npm removed from the runtime image"
docker compose exec app sh -c "which npm || echo 'npm absent: OK'"

step "9. Vulnerability scan"
./scan.sh > /tmp/scan.out 2>&1; rc=$?
grep -E "Total:|No HIGH" /tmp/scan.out || true
echo "scan exit=$rc"
