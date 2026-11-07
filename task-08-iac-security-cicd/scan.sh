#!/usr/bin/env bash
# Usage: ./scan.sh [dossier]   (défaut: terraform/good)
set -uo pipefail
cd "$(dirname "$0")"
CHECKOV="${CHECKOV:-$HOME/.venvs/checkov/bin/checkov}"
"$CHECKOV" -d "${1:-terraform/good}" --framework terraform --compact
