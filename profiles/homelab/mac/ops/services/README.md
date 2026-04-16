# Homelab Services

Docker-based services managed by this repository. All configuration is templated — secrets and network-specific values come from Bitwarden via `.config.json`. Rendered files, persistent data, and runtime state live outside the repo.

## Architecture

```
                    DNS (port 53)          HTTPS (port 443)
                        │                       │
                   ┌────┴────┐             ┌────┴────┐
                   │ AdGuard │             │  Caddy  │
                   │  Home   │             │ (proxy) │
                   └─────────┘             └────┬────┘
                                                │
                                        caddy_proxy network
                                     ┌──────────┼──────────┐
                                     │          │          │
                                ┌────┴───┐ ┌────┴─────-┐ ┌─┴───────--┐
                                │ Uptime │ │ Portainer │ │  Grafana  │
                                │  Kuma  │ │           │ │           │
                                └────────┘ └──────────-┘ └────┬─────-┘
                                                              │ queries
                                                        ┌────-┴─────-┐
                                                        │ Prometheus │◄── scrapes
                                                        └──────────--┘    cAdvisor,
                                                                          Caddy admin,
                                                                          host node_exporter
```

- **AdGuard Home** resolves `${LAB_DOMAIN}` (bare) and `*.${LAB_DOMAIN}` (wildcard) to the homelab IP, forwards everything else to upstream DNS
- **Caddy** terminates TLS using its own internal CA and reverse-proxies to services on the `caddy_proxy` network
- **App services** publish no ports — reachable only through Caddy
- AdGuard Home + Caddy are the only services that publish ports to the host (53, 80, 443)

## Prerequisites

- OrbStack installed (provides Docker)
  - On first install, OrbStack must be launched once via the GUI (Screen Sharing / VNC) to complete its initial setup. After that it starts headlessly on boot.
  - Docker CLI lives at `~/.orbstack/bin/docker` — interactive shells get it via PATH; non-interactive SSH (e.g., `ssh host 'docker ...'`) must use the full path.
- `.config.json` populated with `bw://` references (done during `ops-init`)
- Bitwarden vault unlocked

### Bitwarden fields (added to the existing `dotfiles/homelab/mac` item)

| Field                           | Purpose                                 |
| ------------------------------- | --------------------------------------- |
| `HOMELAB_IP`                    | Mac Mini static IP (DNS rewrite target) |
| `LAB_DOMAIN`                    | Internal domain                         |
| `SERVICES_DATA_DIR`             | Host path for persistent volumes        |
| `UPSTREAM_DNS_1`                | Primary upstream DNS                    |
| `UPSTREAM_DNS_2`                | Secondary upstream DNS                  |
| `GRAFANA_ADMIN_PASSWORD`        | Initial Grafana admin password          |
| `TELEGRAM_BOT_TOKEN_MONITORING` | Token for the dedicated monitoring bot  |
| `TELEGRAM_CHAT_ID_MONITORING`   | Chat ID that receives Grafana alerts    |

When creating `GRAFANA_ADMIN_PASSWORD`, note the following constraint:

> **Note:** the password is interpolated into a YAML Compose file via `envsubst`,
> so it should avoid YAML-special characters (`:`, `#`, `{`, `}`, `[`, `]`, `*`,
> `&`, `|`, `>`, `'`, `"`, `!`, etc.). Stick to alphanumeric plus safe symbols
> like `-`, `_`, `@` to avoid surprises at render time.

## Commands

```bash
dfs services list                # Show all services and status
dfs services init                # Init all services (first-time setup)
dfs services start               # Start all services (ordered)
dfs services stop                # Stop all services (reverse order)

dfs services init <name>         # Init a specific service
dfs services start <name>        # Start a specific service
dfs services stop <name>         # Stop a specific service
dfs services restart <name>      # Restart a specific service
dfs services status <name>       # Show detailed status
```

## Service lifecycle

`dfs services start <name>` performs these steps:

1. Resolve env vars from `.config.json` + Bitwarden
2. Ensure the shared `caddy_proxy` Docker network exists
3. Create the service's data directory under `${SERVICES_DATA_DIR}/<name>/`
4. Render all `*.tmpl` files in the service directory (`envsubst` substitutes `${VAR}` references)
5. Copy service-specific config into the data directory (only for services that need it, e.g. AdGuard Home)
6. Render `caddy.snippet.tmpl` (if present) into `caddy/routes/<name>.snippet`
7. Reload Caddy (if running) to pick up the new route
8. `docker compose up -d`
9. Run `post-start.sh` if present (e.g., AdGuard Home uses this to add DNS rewrites via API)

`dfs services stop <name>` runs `docker compose down`, removes the Caddy route, reloads Caddy.

## Adding a new service

1. Create a directory under `services/` named after the product (e.g., `grafana/`)
2. Add a `docker-compose.yml.tmpl` — this is what defines it as a service
3. If web-facing, add a `caddy.snippet.tmpl` with the reverse proxy route
4. Add new Bitwarden fields to `.config.example.json` if the service needs them
5. Run `dfs services start <name>`

### Minimal service example

**`my_service/docker-compose.yml.tmpl`**

```yaml
services:
  my_service:
    image: some/image:1.2.3
    restart: unless-stopped
    networks:
      - caddy_proxy
      - default
    volumes:
      - ${SERVICES_DATA_DIR}/my_service:/data

networks:
  caddy_proxy:
    external: true
```

**`my_service/caddy.snippet.tmpl`**

```
my-service.${LAB_DOMAIN} {
	tls internal
	reverse_proxy my_service:8080
}
```

## Startup order

When starting all services, infrastructure comes first:

1. AdGuard Home (DNS)
2. Caddy (reverse proxy)
3. Everything else (alphabetical)

Stop runs in reverse. Individual commands have no ordering.

## Data persistence

Each service stores persistent data in `${SERVICES_DATA_DIR}/<service_name>/`. This directory survives container rebuilds, restarts, and OrbStack reinstalls.

**What's repo-managed (source of truth):** templates, compose files, Caddy snippets, scripts.

**What's NOT in the repo:** rendered configs, persistent data, secrets, AdGuard Home admin user (created via the web UI wizard on first start).

## Manual setup steps (not repo-managed)

### 1. UniFi: point DHCP DNS at the homelab

For each VLAN that should use the homelab DNS (and be able to resolve `*.${LAB_DOMAIN}`):

- Settings → Networks → (VLAN) → DHCP settings
- Uncheck "Auto DNS Server"
- Add the homelab IP as primary DNS (e.g., `10.0.192.101`)
- Add the VLAN gateway or a public DNS as fallback

**VLAN30** (homelab) should always point here. Any other VLAN you want to access `*.${LAB_DOMAIN}` from needs the same change.

### 2. UniFi: disable Content Filtering if it intercepts DNS

UniFi's Content Filtering (Settings → Networks → VLAN → Security) transparently intercepts port 53 traffic and answers queries itself, bypassing AdGuard Home entirely. If services don't resolve from a given VLAN despite correct DHCP DNS settings, check here — and also check any `${LAB_DOMAIN}` A records you may have added directly in UniFi (they conflict with AdGuard Home's rewrites).

### 3. Trust Caddy's root CA on each device

Caddy generates its own root CA on first start. To access services via HTTPS without browser warnings, trust the CA on each device:

```bash
# On the homelab, extract the cert
ssh ops@homelab '~/.orbstack/bin/docker cp caddy:/data/caddy/pki/authorities/local/root.crt ~/caddy-root-ca.crt'

# On your Mac, fetch it
scp ops@homelab:/Users/ops/caddy-root-ca.crt ~/Downloads/

# Double-click the .crt — Keychain Access opens
# - Select "System" keychain (admin password)
# - Find "Caddy Local Authority" → double-click → Trust → "Always Trust"
```

For iOS: AirDrop the `.crt` file → Settings → Profile Downloaded → Install → Settings → General → About → Certificate Trust Settings → toggle on.

Trusting on the headless Mac Mini itself requires Screen Sharing (VNC) — `security add-trusted-cert` refuses to run in a non-interactive SSH session on macOS.

### 4. AdGuard Home: first-run setup wizard

On first start, visit `https://dns.${LAB_DOMAIN}` and complete the setup wizard (create admin user). This state lives in the data volume (SQLite DBs and the YAML config), not the repo.

### 5. Uptime Kuma: create admin user and monitors

Visit `https://uptime.${LAB_DOMAIN}` and complete the setup. Monitor configuration is stored in the service's SQLite DB (not repo-managed).

### 6. Portainer: first-run admin user

On first start, visit `https://containers.${LAB_DOMAIN}` and create the
admin user. Portainer closes the initial-user endpoint **5 minutes** after
the container starts for security reasons — if you miss the window, run
`dfs services restart portainer` to reopen it.

Portainer manages the local OrbStack Docker environment via the mounted
`/var/run/docker.sock`. No extra endpoint configuration is needed; the
local environment shows up automatically.

### 7. Native node_exporter (one-time, on the homelab)

`node_exporter` runs natively on macOS so it can read real host sysctl
metrics (Linux containers can't see the macOS host). It is installed by
`make ops-install` via the ops `Brewfile`. Start it once after install:

```sh
brew services start node_exporter
```

It listens on `127.0.0.1:9100` and is reached from inside Docker via
`host.docker.internal:9100` (Prometheus scrapes it there).

To verify after install:

```sh
curl -s http://127.0.0.1:9100/metrics | head -5
```

Expected: a few `# HELP …` lines.

### 8. Telegram monitoring bot (one-time)

The Grafana alert pipeline uses a **dedicated** bot — separate from any
existing Uptime Kuma bot — so monitoring noise stays isolated from
reachability pings.

1. In Telegram, message `@BotFather`. Send `/newbot` and follow the
   prompts (e.g., name it `homelab-monitoring`). Save the HTTP API token
   into the Bitwarden field `TELEGRAM_BOT_TOKEN_MONITORING`.
2. Open a chat with the new bot from your Telegram account and send any
   message (e.g., `/start`).
3. From any machine, fetch the chat ID:

```sh
curl "https://api.telegram.org/bot<TOKEN>/getUpdates"
```

Find the `chat.id` numeric value in the JSON response. Save it into
the Bitwarden field `TELEGRAM_CHAT_ID_MONITORING`.

### 9. Grafana: first-run login

On first start, visit `https://monitoring.${LAB_DOMAIN}` and log in as
`admin` with the password set in `GRAFANA_ADMIN_PASSWORD`. The four
provisioned dashboards (Node Exporter Full, Docker Monitoring,
Prometheus 2.0 Stats, Caddy Monitoring) appear under the "Homelab"
folder. There is no setup wizard.

Provisioned alert rules and the Telegram contact point appear under
**Alerting** in the left nav. To smoke-test the wiring, edit any rule
temporarily to a threshold you are currently exceeding (e.g., HostHighCPU
threshold to `1`); a Telegram message should arrive within ~1 minute.
Restore the threshold when done.

## Gotchas worth knowing

### AdGuard Home wipes DNS rewrites on startup

AdGuard Home re-writes its own config on startup during schema migrations and first-run setup, stripping the `rewrites` list. The template still defines rewrites (for completeness), but they don't survive. The permanent fix is the `post-start.sh` hook that re-adds rewrites via AdGuard's HTTP API after the container is running. This is idempotent — duplicate adds are silently ignored.

### Wildcard does not match the bare domain

AdGuard Home's `*.${LAB_DOMAIN}` rewrite matches `uptime.${LAB_DOMAIN}`, `dns.${LAB_DOMAIN}`, etc., but NOT `${LAB_DOMAIN}` itself. The post-start hook adds **two** rewrites: one wildcard, one for the bare domain.

### The `caddy_proxy` network is created by services.sh, not Caddy's compose

Services reference `caddy_proxy` as `external: true` in their compose files. `services.sh` creates the network via `docker network create` before starting any service, so all services (including Caddy) treat it as pre-existing.

### OrbStack on headless macOS

- Requires GUI launch once to complete initial setup
- Reopening the VNC session shows the login screen — the session locks when disconnected. Disable screen lock in System Settings → Lock Screen for a smoother experience.
- VNC "High performance" mode often fails on first connect to a headless Mac; drop to Adaptive, then switch via the **View** menu in Screen Sharing after connecting.

## Future work (intentionally not implemented)

- **Weekly Telegram digest** — a small script queries Prometheus for 7-day
  averages (CPU, memory, disk) and posts a text summary to the monitoring
  Telegram channel weekly via launchd. Deferred from the initial monitoring
  rollout. Spec lives at
  `docs/superpowers/specs/2026-04-13-grafana-prometheus-monitoring-design.md`.
- **Per-service exporters for AdGuard Home and Uptime Kuma** — same spec.
- **Host temperature metrics via node_exporter textfile collector** — same
  spec.
