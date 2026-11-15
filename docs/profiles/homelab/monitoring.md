# 📊 Monitoring stack

Metrics flow into Prometheus, dashboards and alert rules live in Grafana, Portainer manages containers, and Uptime Kuma runs synthetic checks. Both Grafana and Uptime Kuma alert through Telegram, each with its own bot.

| Service     | URL                                | Purpose                                                     |
| ----------- | ---------------------------------- | ----------------------------------------------------------- |
| Uptime Kuma | `https://uptime.${LAB_DOMAIN}`     | Synthetic checks + Telegram alerts                          |
| Grafana     | `https://monitoring.${LAB_DOMAIN}` | Dashboards + alert rules (Telegram)                         |
| Prometheus  | internal                           | Metrics store; scrapes node_exporter, macmon, Caddy, exporters |
| Portainer   | `https://containers.${LAB_DOMAIN}` | Docker UI for the OrbStack environment                      |
| Exporters   | internal                           | Metrics for the *Arr stack, qBittorrent, Jellyfin, Seerr    |

First-run logins and the native host exporters are in [Manual setup](manual-setup.md).

**Grafana dashboards**, provisioned into the **Homelab** folder: Node Exporter Full, macmon Overview, Prometheus Stats, Caddy Monitoring, Media Dashboard (Sonarr/Radarr/Prowlarr), qBittorrent, Jellyfin, Seerr.

## 📡 Exporters

One Compose project on the shared `metrics_internal` network, managed as `dfs services {init,start,stop,restart,status} exporters`. Each container polls its target's HTTP API.

| Container              | Image                                                           | Target             | Secret                 |
| ---------------------- | --------------------------------------------------------------- | ------------------ | ---------------------- |
| `exportarr-sonarr`     | `ghcr.io/onedr0p/exportarr:v2.3.0`                              | `sonarr:8989`      | `SONARR_API_KEY`       |
| `exportarr-radarr`     | `ghcr.io/onedr0p/exportarr:v2.3.0`                              | `radarr:7878`      | `RADARR_API_KEY`       |
| `exportarr-prowlarr`   | `ghcr.io/onedr0p/exportarr:v2.3.0`                              | `prowlarr:9696`    | `PROWLARR_API_KEY`     |
| `exportarr-bazarr`     | `ghcr.io/onedr0p/exportarr:v2.3.0`                              | `bazarr:6767`      | `BAZARR_API_KEY`       |
| `qbittorrent-exporter` | `ghcr.io/esanchezm/prometheus-qbittorrent-exporter:sha-3e55078` | `qbittorrent:8080` | `QBITTORRENT_PASSWORD` |
| `jellyfin-exporter`    | `rebelcore/jellyfin-exporter:v1.5.0` (Docker Hub)               | `jellyfin:8096`    | `JELLYFIN_API_KEY`     |
| `seerr-exporter`       | `ghcr.io/opspotes/jellyseerr-exporter:1.4.0` (amd64 only)       | `seerr:5055`       | `SEERR_API_KEY`        |

### Setting up the keys

1. Get each key from its service:

   | Service                             | Where                                         |
   | ----------------------------------- | --------------------------------------------- |
   | Sonarr / Radarr / Prowlarr / Bazarr | Settings → General → API Key                  |
   | Jellyfin                            | Dashboard → API Keys → New (name: `exporter`) |
   | Seerr                               | Settings → General → API Key                  |
   | qBittorrent                         | The admin password                            |

2. Store each in the `dotfiles/homelab/mac` Bitwarden item under the field in the "Secret" column.
3. Re-render and restart:

   ```sh
   cd profiles/homelab/mac/ops
   dotfiles configs unlock
   dotfiles configs link
   dfs services restart exporters
   ```

### Verifying

Port 9090 is not published on the host, so query from inside the Prometheus container:

```sh
# Lists unhealthy scrape targets; expect []
docker exec prometheus wget -qO- http://localhost:9090/api/v1/targets \
  | jq '[.data.activeTargets[] | select(.health!="up") | .labels.job]'

# One exporter directly
docker exec prometheus wget -qO- http://exportarr-sonarr:9707/metrics | grep '^sonarr_'
```

### Notes

- **exportarr** — one image, one container per *Arr; the *Arr name is the `command`. `ENABLE_ADDITIONAL_METRICS` is on for Sonarr and Radarr only.
- **qbittorrent-exporter** — upstream has no semver tags; pinned to a `sha-<short>` tag. Bump deliberately.
- **jellyfin-exporter** — on Docker Hub, not GHCR. Newer versions renamed the env vars from `JELLYFIN_BASEURL`/`APIKEY` to `JELLYFIN_ADDRESS`/`JELLYFIN_TOKEN`.
- **seerr-exporter** — a fork of `WillFantom/overseerr-exporter`. It reads `JELLYSEERR_*` env vars and emits `jellyseerr_*` metrics; those names are baked into the binary. amd64 only, so it runs under Rosetta (`platform: linux/amd64`).

## 📋 Uptime Kuma inventory

Uptime Kuma keeps all its configuration in its own SQLite database (`${SERVICES_DATA_DIR}/uptime_kuma/kuma.db`), not in this repo. This section is the record to rebuild it from.

> Update this section whenever monitors, tags or notification providers change.

### Notification

| Name     | Type     | Default | Notes                                      |
| -------- | -------- | ------- | ------------------------------------------ |
| Telegram | Telegram | Yes     | Bot token + chat ID in Bitwarden, not here |

### Tags

| Name       | Color     |
| ---------- | --------- |
| infra      | `#D97706` |
| service    | `#2563EB` |
| storage    | `#4B5563` |
| monitoring | `#DB2777` |
| media      | `#7C3AED` |
| downloads  | `#059669` |

### Monitor defaults

| Setting                  | Value                                                             |
| ------------------------ | ----------------------------------------------------------------- |
| Heartbeat interval       | 60s                                                               |
| Retries                  | 2                                                                 |
| Heartbeat retry interval | 60s                                                               |
| Method                   | `GET`                                                             |
| Accepted status codes    | `200-299`                                                         |
| Max redirects            | 10                                                                |
| Ignore TLS error         | off (Caddy root CA is trusted via `NODE_EXTRA_CA_CERTS` in the compose file) |
| Notification             | Telegram (default)                                                |

### Monitors

| Name                | Tags                | Type | Target                                        |
| ------------------- | ------------------- | ---- | --------------------------------------------- |
| HomeLab Host        | infra               | Ping | Mac Mini static IP (Bitwarden `HOMELAB_IP`)   |
| UniFi Router        | infra               | Ping | Router IP (LAN gateway)                       |
| Internet            | infra               | Ping | A public DNS resolver IP                      |
| DNS Resolution      | infra               | DNS  | `google.com:53`, resolver: router IP, record type A |
| Uptime Kuma         | service, monitoring | HTTP | `https://uptime.${LAB_DOMAIN}`                |
| Portainer           | service, monitoring | HTTP | `https://containers.${LAB_DOMAIN}/api/status` |
| Grafana             | service, monitoring | HTTP | `https://monitoring.${LAB_DOMAIN}/api/health` |
| FileBrowser Quantum | service, storage    | HTTP | `https://files.${LAB_DOMAIN}/health`          |
| qBittorrent         | service, downloads  | HTTP | `https://downloads.${LAB_DOMAIN}`             |
| Bazarr              | service, media      | HTTP | `https://bazarr.media.${LAB_DOMAIN}`          |
| Jellyfin            | service, media      | HTTP | `https://jellyfin.media.${LAB_DOMAIN}`        |
| Prowlarr            | service, media      | HTTP | `https://prowlarr.media.${LAB_DOMAIN}`        |
| Radarr              | service, media      | HTTP | `https://radarr.media.${LAB_DOMAIN}`          |
| Seerr               | service, media      | HTTP | `https://media.${LAB_DOMAIN}`                 |
| Sonarr              | service, media      | HTTP | `https://sonarr.media.${LAB_DOMAIN}`          |

### Restore procedure

After a fresh install (`dfs services start uptime_kuma` and the first-run admin setup):

1. **Settings → Notifications → Setup Notification:** recreate `Telegram` with the bot token and chat ID from Bitwarden; tick **Default enabled** so new monitors inherit it.
2. **Settings → Tags:** create the six tags with the colors above.
3. **Add New Monitor:** add each monitor from the table with the defaults, and assign its tags.
4. Check that each turns green within ~60 seconds.

### Re-exporting the inventory

To regenerate the tables from the live DB, on the homelab:

```sh
# Monitors
docker exec uptime_kuma sqlite3 /app/data/kuma.db -header -column "SELECT name, type, url, hostname, port FROM monitor ORDER BY id;"

# Tags
docker exec uptime_kuma sqlite3 /app/data/kuma.db -header -column "SELECT name, color FROM tag;"

# Monitor → tag assignments
docker exec uptime_kuma sqlite3 /app/data/kuma.db -header -column "SELECT m.name AS monitor, t.name AS tag FROM monitor_tag mt JOIN monitor m ON m.id=mt.monitor_id JOIN tag t ON t.id=mt.tag_id ORDER BY m.name;"

# Notifications
docker exec uptime_kuma sqlite3 /app/data/kuma.db -header -column "SELECT name, active, is_default FROM notification;"
```
