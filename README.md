# Wiki.js für swuniverse

Eigenständiger Wiki.js-Stack für `wiki.swuniverse.net`. Wiki.js und PostgreSQL werden unabhängig vom `core`-Repository betrieben.

## Architektur

- Wiki.js: `requarks/wiki:2`
- PostgreSQL: `postgres:16-alpine`
- keine veröffentlichten Host-Ports
- Caddy aus `core` erreicht Wiki.js über das externe Docker-Netzwerk `swuniverse_proxy`
- persistente Docker-Volumes für Datenbank und Wiki-Daten

Der VPS muss das Netzwerk einmalig enthalten:

```bash
docker network create --driver bridge swuniverse_proxy
```

## Lokaler Start

```bash
cp .env.example .env
# Passwort in .env setzen
docker compose --env-file .env up -d
```

Für den lokalen Zugriff kann vorübergehend ein Port ergänzt werden; produktiv bleibt Wiki.js ausschließlich über Caddy erreichbar.

## VPS-Deployment

Auf dem VPS unter `/opt/swuniverse/wiki`:

```bash
cp .env.example .env.production
chmod 600 .env.production
# starkes PostgreSQL-Passwort eintragen
./deploy-remote.sh
```

Das Skript prüft das externe Netzwerk und die Compose-Konfiguration, lädt Images, startet den Stack und wartet auf PostgreSQL sowie Wiki.js. `.env.production` und Docker-Volumes bleiben außerhalb von Git erhalten.

## Caddy im Core-Repository

Im `core`-Repository müssen Caddy und Wiki dasselbe externe Netzwerk verwenden.

`Caddyfile`:

```caddyfile
wiki.swuniverse.net {
    reverse_proxy wiki:3000
}
```

Im produktiven `core/docker-compose.prod.yml` muss das Caddy-Netzwerk ergänzt werden:

```yaml
services:
  caddy:
    networks:
      - default
      - mailcow
      - proxy

networks:
  proxy:
    external: true
    name: swuniverse_proxy
```

Danach den Core-Stack neu deployen, damit Caddy die neue Route lädt. Der DNS-A- bzw. AAAA-Record von `wiki.swuniverse.net` muss auf den VPS zeigen. Caddy übernimmt anschließend TLS.

## Backups

Die PostgreSQL-Datenbank sollte regelmäßig auf dem VPS gesichert werden. Dafür steht ein Skript bereit:

```bash
./backup-wiki.sh
```

Das Skript liest `.env.production`, erzeugt ein zeitgestempeltes SQL-Dump unter `backup/` und setzt die Datei auf `chmod 600`. Backups dürfen nicht in Git committed werden. Die Sicherungsdateien sollten zusätzlich auf ein separates Ziel kopiert werden; ein lokales Dump allein schützt nicht vor einem VPS- oder Volume-Verlust.
