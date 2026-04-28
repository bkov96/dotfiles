# Monitoring Stack

Observability and uptime tracking for the homelab. Metrics flow into
Prometheus, dashboards live in Grafana, container management goes
through Portainer, and synthetic checks run from Uptime Kuma with
Telegram alerting.

## Contents

- [Services](#services)
- [Uptime Kuma — monitor inventory](#uptime-kuma--monitor-inventory)

## Services

| Service     | Domain                             | Purpose                                                          |
| ----------- | ---------------------------------- | ---------------------------------------------------------------- |
| Uptime Kuma | `uptime.${LAB_DOMAIN}`             | Synthetic checks + Telegram alerts                               |
| Grafana     | `monitoring.${LAB_DOMAIN}`         | Dashboards + alert rules (Telegram)                              |
| Prometheus  | (internal)                         | Metrics store, scrapes node_exporter, macmon, caddy, exporters   |
| Portainer   | `containers.${LAB_DOMAIN}`         | Docker UI for the OrbStack environment                           |
| Exporters   | (internal)                         | Prometheus exporters for the *Arr stack, qBittorrent, Jellyfin, Seerr |

First-launch instructions for each service live in the parent
[services README](../README.md#manual-setup-steps-not-repo-managed).

## Uptime Kuma — monitor inventory

Uptime Kuma stores all monitor configuration in its own SQLite database
(`${SERVICES_DATA_DIR}/uptime_kuma/kuma.db`), not in this repo. This
section documents the current setup so it can be reconstructed manually
after a fatal incident or fresh install.

> Update this section whenever monitors, tags, or notification providers
> change.

### Notifications

| Name     | Type     | Default | Notes                                               |
| -------- | -------- | ------- | --------------------------------------------------- |
| Telegram | Telegram | Yes     | Bot token + chat ID kept in Bitwarden, not in repo. |

Recreate the Telegram provider via **Settings → Notifications → Setup
Notification**, mark it as the default so new monitors inherit it.

### Tags

| Name       | Color     |
| ---------- | --------- |
| infra      | `#D97706` |
| service    | `#2563EB` |
| storage    | `#4B5563` |
| monitoring | `#DB2777` |
| media      | `#7C3AED` |
| downloads  | `#059669` |

### Defaults applied to every monitor

Unless noted otherwise in the monitor table:

- **Heartbeat interval:** 60s
- **Retries:** 2
- **Heartbeat retry interval:** 60s
- **Method:** `GET`
- **Accepted status codes:** `200-299`
- **Max redirects:** 10
- **Ignore TLS error:** off (Caddy root CA is trusted via
  `NODE_EXTRA_CA_CERTS` in the compose file)
- **Notification:** Telegram (default)

### Monitors

#### infra

| Name           | Type | Target / URL    | Notes                                                       |
| -------------- | ---- | --------------- | ----------------------------------------------------------- |
| HomeLab Host   | Ping | _Mac Mini IP_   | Static LAN IP (Bitwarden: `HOMELAB_IP`)                     |
| UniFi Router   | Ping | _Router IP_     | LAN gateway address                                         |
| Internet       | Ping | _Public DNS IP_ | External reachability check (e.g., a public DNS resolver)   |
| DNS Resolution | DNS  | `google.com:53` | Resolver: _router IP_, record type A — tests router DNS     |

#### service + monitoring

| Name        | Type | URL                                           |
| ----------- | ---- | --------------------------------------------- |
| Uptime Kuma | HTTP | `https://uptime.${LAB_DOMAIN}`                |
| Portainer   | HTTP | `https://containers.${LAB_DOMAIN}/api/status` |
| Grafana     | HTTP | `https://monitoring.${LAB_DOMAIN}/api/health` |

#### service + storage

| Name                | Type | URL                                  |
| ------------------- | ---- | ------------------------------------ |
| FileBrowser Quantum | HTTP | `https://files.${LAB_DOMAIN}/health` |

#### service + downloads

| Name        | Type | URL                               |
| ----------- | ---- | --------------------------------- |
| qBittorrent | HTTP | `https://downloads.${LAB_DOMAIN}` |

#### service + media

| Name     | Type | URL                                    |
| -------- | ---- | -------------------------------------- |
| Bazarr   | HTTP | `https://bazarr.media.${LAB_DOMAIN}`   |
| Jellyfin | HTTP | `https://jellyfin.media.${LAB_DOMAIN}` |
| Prowlarr | HTTP | `https://prowlarr.media.${LAB_DOMAIN}` |
| Radarr   | HTTP | `https://radarr.media.${LAB_DOMAIN}`   |
| Seerr    | HTTP | `https://media.${LAB_DOMAIN}`          |
| Sonarr   | HTTP | `https://sonarr.media.${LAB_DOMAIN}`   |

### Restore procedure

After a fresh Uptime Kuma install (`dfs services start uptime_kuma` and
the first-run admin setup):

1. **Settings → Notifications** — recreate the `Telegram` provider with
   the bot token + chat ID from Bitwarden, tick **Default enabled**.
2. **Settings → Tags** — create the six tags above with the listed
   colors.
3. **+ Add New Monitor** — add each monitor from the tables above using
   the documented defaults. Assign the listed tags. The default Telegram
   notification will attach automatically.
4. Verify each monitor turns green within ~60 seconds.

### Re-exporting this inventory

To regenerate these tables from the live DB (after adding new monitors),
run these one-liners on the homelab host:

```bash
# Monitors
docker exec uptime_kuma sqlite3 /app/data/kuma.db -header -column "SELECT name, type, url, hostname, port FROM monitor ORDER BY id;"

# Tags
docker exec uptime_kuma sqlite3 /app/data/kuma.db -header -column "SELECT name, color FROM tag;"

# Monitor → tag assignments
docker exec uptime_kuma sqlite3 /app/data/kuma.db -header -column "SELECT m.name AS monitor, t.name AS tag FROM monitor_tag mt JOIN monitor m ON m.id=mt.monitor_id JOIN tag t ON t.id=mt.tag_id ORDER BY m.name;"

# Notifications
docker exec uptime_kuma sqlite3 /app/data/kuma.db -header -column "SELECT name, active, is_default FROM notification;"
```
