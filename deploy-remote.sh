#!/usr/bin/env bash
set -euo pipefail

COMPOSE=(docker compose --project-name wiki --env-file .env.production -f docker-compose.yml)

if [[ ! -f .env.production ]]; then
  echo "Fehler: .env.production fehlt." >&2
  exit 1
fi

if ! docker network inspect swuniverse_proxy >/dev/null 2>&1; then
  echo "Fehler: Docker-Netzwerk swuniverse_proxy fehlt." >&2
  exit 1
fi

"${COMPOSE[@]}" config --quiet
"${COMPOSE[@]}" pull
"${COMPOSE[@]}" up -d --remove-orphans

for _ in $(seq 1 60); do
  if [[ "$(docker inspect -f '{{.State.Health.Status}}' wiki-db-1 2>/dev/null || true)" == "healthy" ]] && \
     [[ "$(docker inspect -f '{{.State.Running}}' wiki-wiki-1 2>/dev/null || true)" == "true" ]]; then
    echo "Wiki.js ist gestartet."
    exit 0
  fi
  sleep 2
done

echo "Fehler: Wiki.js wurde nicht rechtzeitig bereit." >&2
"${COMPOSE[@]}" ps
exit 1
