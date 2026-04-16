# Service Reorganization & README Refresh

Organize homelab services into category directories, add Grafana dashboard tags, and revise all README files.

## 1. Service Directory Reorganization

### Current structure

```
services/
  adguard_home/
  caddy/
  grafana/
  portainer/
  prometheus/
  uptime_kuma/
```

### New structure

```
services/
  network/
    adguard_home/
    caddy/
  monitoring/
    grafana/
    portainer/
    prometheus/
    uptime_kuma/
```

### Category assignments

| Category     | Services                                    |
| ------------ | ------------------------------------------- |
| `network`    | `adguard_home`, `caddy`                     |
| `monitoring` | `grafana`, `prometheus`, `portainer`, `uptime_kuma` |

### Constraints

- Service names must remain unique across categories (already true).
- Data directories remain flat: `$SERVICES_DATA_DIR/<name>/` (no category prefix).
- Docker project names remain flat (service name only).
- `INFRA_SERVICES` startup ordering stays as an explicit list of service names.
- Categories are repo-only organization; they do not affect runtime behavior.

## 2. services.sh Changes

### Discovery

Replace single-level glob with two-level:

```sh
# Before
all_services() {
  for dir in "$SERVICES_DIR"/*/; do
    [ -f "$dir/docker-compose.yml.tmpl" ] && basename "$dir"
  done
}

# After
all_services() {
  for dir in "$SERVICES_DIR"/*/*/; do
    [ -f "$dir/docker-compose.yml.tmpl" ] && basename "$dir"
  done
}
```

### Path resolution

Add a `service_dir()` helper that maps a service name to its full path:

```sh
service_dir() {
  for dir in "$SERVICES_DIR"/*/*/; do
    [ -f "$dir/docker-compose.yml.tmpl" ] && [ "$(basename "$dir")" = "$1" ] && printf '%s' "${dir%/}" && return
  done
}
```

### Path reference updates

Every occurrence of `$SERVICES_DIR/$_svc` or `$SERVICES_DIR/$1` must be replaced with a call to `service_dir`. Affected functions:

- `validate_service` (line 60)
- `render_templates` (line 88)
- `install_config_to_data` (lines 104-105)
- `install_caddy_route` (lines 120-123)
- `remove_caddy_route` (line 130 -- uses `CADDY_ROUTES_DIR`, unaffected)
- `reload_caddy` (line 138 -- hardcoded `caddy/docker-compose.yml`, must update)
- `is_running` (line 146)
- `do_init` (lines 176-184)
- `do_start` (lines 188-204)
- `do_stop` (lines 210-221)
- `do_status` (lines 232-237)

### CADDY_ROUTES_DIR

Update from:
```sh
CADDY_ROUTES_DIR="$SERVICES_DIR/caddy/routes"
```
To:
```sh
CADDY_ROUTES_DIR="$SERVICES_DIR/network/caddy/routes"
```

### reload_caddy

Update the hardcoded Caddy compose path:
```sh
# Before
docker compose -f "$SERVICES_DIR/caddy/docker-compose.yml" ...

# After — use service_dir
docker compose -f "$(service_dir caddy)/docker-compose.yml" ...
```

## 3. Grafana Dashboard Tags

Update the top-level `"tags"` field in each provisioned dashboard JSON:

| Dashboard                  | Tags                          |
| -------------------------- | ----------------------------- |
| `caddy-monitoring.json`    | `["network", "caddy"]`        |
| `node-exporter-full.json`  | `["monitoring", "host"]`      |
| `prometheus-stats.json`    | `["monitoring", "prometheus"]` |

Only the top-level `"tags"` field is changed. Nested annotation `"tags"` inside panels are left untouched.

## 4. README Updates

### 4.1 Root README (`/README.md`)

- Change opening line from "Personal machine configuration" to "Machine configuration manager"
- Add table of contents at the top
- Add "Services" command group table:
  - `services list` -- Show all services and status
  - `services init [name]` -- Init all or a specific service
  - `services start [name]` -- Start all or a specific service
  - `services stop [name]` -- Stop all or a specific service
  - `services restart [name]` -- Restart a specific service
  - `services status [name]` -- Show detailed status
- Add "Profiles & Platforms" section listing available profiles with links:
  - `work/mac` -- work machine
  - `homelab/mac` -- homelab server (with `admin` and `ops` users)
  - `github/ci` -- CI environment
- Update structure tree to reflect `services/<category>/<name>/` layout
- Remove the "What's next" section and its TOC entry

### 4.2 Homelab Bootstrap README (`/profiles/homelab/mac/README.md`)

- Add table of contents at the top
- No other content changes (still accurate)

### 4.3 Services README (`/profiles/homelab/mac/ops/services/README.md`)

- Add table of contents at the top
- Update "Adding a new service" to reference category directories (`services/<category>/` instead of `services/`)
- Update minimal service example path (e.g. `monitoring/my_service/docker-compose.yml.tmpl`)
- Update architecture diagram to visually group services by category

### 4.4 Delete `docs/homelab.md`

Content is either outdated (abstract naming convention, future service management) or covered by the services README. Remove entirely. The root README's "What's next" link to it is also removed (see 4.1).

## 5. Docker Image Version Upgrades

### Version changes

| Image | Current | Target | Notes |
| ----- | ------- | ------ | ----- |
| caddy | 2.11.2-alpine | no change | |
| prom/prometheus | v3.11.2 | no change | |
| grafana/grafana-oss | 13.0.0 | no change | |
| portainer/portainer-ce | 2.21.5 | **2.39.1** | LTS, supported through Nov 2026 |
| louislam/uptime-kuma | 1.23.17 | **2.2.1** | Major version bump |
| adguard/adguardhome | v0.107.73 | **v0.107.74** | Patch bump |

### Portainer 2.21.5 -> 2.39.1

- Database auto-migrates on startup. No manual steps.
- Add `--trusted-origins https://containers.${LAB_DOMAIN}` to the `command:` in `docker-compose.yml.tmpl` to handle CSRF protection behind Caddy reverse proxy (required since Portainer 2.32.0).
- No port, volume, or env var changes.

### Uptime Kuma 1.23.17 -> 2.2.1

- Database auto-migrates on first startup. Do not interrupt.
- Alpine images no longer available in v2 -- use `louislam/uptime-kuma:2.2.1` (Debian-based).
- No port, volume, or env var changes.
- Backup/restore JSON feature removed (not used by this repo).
- SMTP notification templates switched to LiquidJS (not configured by this repo).

### AdGuard Home v0.107.73 -> v0.107.74

- Patch bump. No breaking changes.

## 6. README Fixes (additional)

### Services README -- dashboard list correction

Section 9 (Grafana first-run login) mentions "four provisioned dashboards" including "Docker Monitoring". Only three dashboards exist in provisioning: Node Exporter Full, Prometheus Stats, Caddy Monitoring. Fix the count and list.

### Services README -- "Future work" review

Review deferred items (weekly Telegram digest, per-service exporters, host temperature metrics) and prune any that are no longer planned.

## 7. Files Changed

| Action | File |
| ------ | ---- |
| Move   | `services/adguard_home/` -> `services/network/adguard_home/` |
| Move   | `services/caddy/` -> `services/network/caddy/` |
| Move   | `services/grafana/` -> `services/monitoring/grafana/` |
| Move   | `services/portainer/` -> `services/monitoring/portainer/` |
| Move   | `services/prometheus/` -> `services/monitoring/prometheus/` |
| Move   | `services/uptime_kuma/` -> `services/monitoring/uptime_kuma/` |
| Edit   | `profiles/homelab/mac/ops/scripts/services.sh` |
| Edit   | `services/monitoring/grafana/provisioning/dashboards/caddy-monitoring.json` |
| Edit   | `services/monitoring/grafana/provisioning/dashboards/node-exporter-full.json` |
| Edit   | `services/monitoring/grafana/provisioning/dashboards/prometheus-stats.json` |
| Edit   | `services/monitoring/portainer/docker-compose.yml.tmpl` (version + trusted-origins) |
| Edit   | `services/monitoring/uptime_kuma/docker-compose.yml.tmpl` (version) |
| Edit   | `services/network/adguard_home/docker-compose.yml.tmpl` (version) |
| Edit   | `/README.md` |
| Edit   | `profiles/homelab/mac/README.md` |
| Edit   | `profiles/homelab/mac/ops/services/README.md` |
| Delete | `docs/homelab.md` |
