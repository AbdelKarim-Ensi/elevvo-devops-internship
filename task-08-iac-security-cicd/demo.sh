#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"
CHECKOV="${CHECKOV:-$HOME/.venvs/checkov/bin/checkov}"
TFIMG=hashicorp/terraform:1.9.8
LSIMG=localstack/localstack:3.8.1
GLIMG=zricethezav/gitleaks:latest

step()   { echo; echo "=== $1. $2 ==="; }
expect() { if [ "$2" = "$1" ]; then echo "OK -> exit=$2 ($3)"; else echo "KO -> exit=$2, attendu $1 ($3)"; fi; }
tf()     { docker run --rm --network host -u "$(id -u):$(id -g)" -e HOME=/tmp \
             -v "$PWD":/work -w /work "$TFIMG" "$@"; }

cleanup() { docker rm -f localstack-task08 >/dev/null 2>&1; }
trap cleanup EXIT

step 0 "Démarrage de LocalStack (S3)"
cleanup
docker run -d --name localstack-task08 --network host -e SERVICES=s3 "$LSIMG" >/dev/null
until curl -sf http://localhost:4566/_localstack/health >/dev/null; do sleep 2; done
echo "LocalStack prêt"

step 1 "Checkov sur le Terraform conforme (doit PASSER)"
"$CHECKOV" -d terraform/good --framework terraform --compact --quiet; rc=$?
expect 0 "$rc" "code sécurisé accepté"

step 2 "Checkov sur le Terraform non sécurisé (doit ÉCHOUER)"
"$CHECKOV" -d terraform/bad --framework terraform --compact --quiet; rc=$?
expect 1 "$rc" "S3 public/non chiffré rejeté, déploiement bloqué"

step 3 "Terraform plan + apply sur LocalStack (code conforme)"
( cd terraform/good && rm -rf .terraform terraform.tfstate* tfplan \
  && tf init -input=false >/dev/null \
  && tf plan -input=false -out=tfplan | tail -n 5 \
  && tf apply -input=false -auto-approve tfplan | tail -n 3 \
  && echo "--- chiffrement appliqué :" \
  && tf state show aws_s3_bucket_server_side_encryption_configuration.this | grep -E 'sse_algorithm|bucket ' ); rc=$?
expect 0 "$rc" "bucket créé dans LocalStack"
( cd terraform/good && tf destroy -input=false -auto-approve >/dev/null 2>&1; rm -rf .terraform terraform.tfstate* tfplan )

step 4 "Gitleaks sur un fichier contenant une fausse clé AWS (doit ÉCHOUER)"
T="$(mktemp -d)"
# Fausse clé au format AWS réel (AKIA + 16 car. A-Z/2-7), générée à l'exécution :
# aucun secret littéral dans le dépôt.
FAKE_ID="AKIA$(head -c 400 /dev/urandom | tr -dc 'A-Z2-7' | head -c 16)"
FAKE_SECRET="$(head -c 600 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 40)"
printf 'AWS_ACCESS_KEY_ID = "%s"\nAWS_SECRET_ACCESS_KEY = "%s"\n' "$FAKE_ID" "$FAKE_SECRET" > "$T/config.py"
docker run --rm -v "$T":/scan "$GLIMG" detect --no-git --source /scan --no-banner -v --redact 2>&1 | grep -E 'RuleID|File|leaks found'
rc=${PIPESTATUS[0]}
expect 1 "$rc" "clé AWS détectée, merge bloqué"
rm -rf "$T"

step 5 "Gitleaks sur le dossier de la tâche (doit PASSER)"
docker run --rm -v "$ROOT":/scan "$GLIMG" detect --no-git --source /scan --no-banner 2>&1 | tail -n 3
rc=${PIPESTATUS[0]}
expect 0 "$rc" "aucun secret dans le code livré"
