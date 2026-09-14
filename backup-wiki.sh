#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f .env.production ]]; then
  echo "Fehler: .env.production fehlt." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env.production
set +a

: "${POSTGRES_USER:?POSTGRES_USER fehlt}"
: "${POSTGRES_DB:?POSTGRES_DB fehlt}"

mkdir -p backup
output="backup/wiki-$(date +%Y-%m-%dT%H%M%S).sql"
docker compose --project-name wiki --env-file .env.production exec -T db \
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$output"

chmod 600 "$output"
echo "Backup erstellt: $output"
