# Service Reorganization & README Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Organize homelab services into category directories, upgrade Docker images, add Grafana dashboard tags, and revise all README files.

**Architecture:** Services move from a flat `services/<name>/` layout into `services/<category>/<name>/`. The `services.sh` script gains a `service_dir()` helper for two-level discovery while keeping runtime behavior (data dirs, Docker project names, startup order) flat. Three Docker images are upgraded with breaking-change mitigations applied.

**Tech Stack:** Shell (POSIX sh), Docker Compose templates, Grafana JSON dashboards, Markdown

---

### Task 1: Move service directories into categories

**Files:**
- Move: `profiles/homelab/mac/ops/services/adguard_home/` -> `profiles/homelab/mac/ops/services/network/adguard_home/`
- Move: `profiles/homelab/mac/ops/services/caddy/` -> `profiles/homelab/mac/ops/services/network/caddy/`
- Move: `profiles/homelab/mac/ops/services/grafana/` -> `profiles/homelab/mac/ops/services/monitoring/grafana/`
- Move: `profiles/homelab/mac/ops/services/portainer/` -> `profiles/homelab/mac/ops/services/monitoring/portainer/`
- Move: `profiles/homelab/mac/ops/services/prometheus/` -> `profiles/homelab/mac/ops/services/monitoring/prometheus/`
- Move: `profiles/homelab/mac/ops/services/uptime_kuma/` -> `profiles/homelab/mac/ops/services/monitoring/uptime_kuma/`

- [ ] **Step 1: Create category directories and move services**

```bash
cd profiles/homelab/mac/ops/services
mkdir -p network monitoring
git mv adguard_home network/
git mv caddy network/
git mv grafana monitoring/
git mv portainer monitoring/
git mv prometheus monitoring/
git mv uptime_kuma monitoring/
```

- [ ] **Step 2: Verify the new structure**

Run: `find profiles/homelab/mac/ops/services -name 'docker-compose.yml.tmpl' | sort`

Expected:
```
profiles/homelab/mac/ops/services/monitoring/grafana/docker-compose.yml.tmpl
profiles/homelab/mac/ops/services/monitoring/portainer/docker-compose.yml.tmpl
profiles/homelab/mac/ops/services/monitoring/prometheus/docker-compose.yml.tmpl
profiles/homelab/mac/ops/services/monitoring/uptime_kuma/docker-compose.yml.tmpl
profiles/homelab/mac/ops/services/network/adguard_home/docker-compose.yml.tmpl
profiles/homelab/mac/ops/services/network/caddy/docker-compose.yml.tmpl
```

- [ ] **Step 3: Commit**

```bash
git add -A profiles/homelab/mac/ops/services/
git commit -m "refactor(homelab): organize services into category directories

Move services into network/ (adguard_home, caddy) and monitoring/
(grafana, portainer, prometheus, uptime_kuma) categories."
```

---

### Task 2: Update services.sh for two-level discovery

**Files:**
- Modify: `profiles/homelab/mac/ops/scripts/services.sh`

- [ ] **Step 1: Update CADDY_ROUTES_DIR (line 20)**

Change:
```sh
CADDY_ROUTES_DIR="$SERVICES_DIR/caddy/routes"
```
To:
```sh
CADDY_ROUTES_DIR="$SERVICES_DIR/network/caddy/routes"
```

- [ ] **Step 2: Update all_services() (lines 32-36)**

Change:
```sh
all_services() {
  for dir in "$SERVICES_DIR"/*/; do
    [ -f "$dir/docker-compose.yml.tmpl" ] && basename "$dir"
  done
}
```
To:
```sh
all_services() {
  for dir in "$SERVICES_DIR"/*/*/; do
    [ -f "$dir/docker-compose.yml.tmpl" ] && basename "$dir"
  done
}
```

- [ ] **Step 3: Add service_dir() helper after all_services()**

Insert after the `all_services` function (after line 36):

```sh
# Resolve a service name to its full directory path
service_dir() {
  for dir in "$SERVICES_DIR"/*/*/; do
    [ -f "$dir/docker-compose.yml.tmpl" ] && [ "$(basename "$dir")" = "$1" ] && printf '%s' "${dir%/}" && return
  done
}
```

- [ ] **Step 4: Update validate_service() (line 59-65)**

Change:
```sh
validate_service() {
  if [ ! -f "$SERVICES_DIR/$1/docker-compose.yml.tmpl" ]; then
    log_error "Unknown service: $1"
    log_info "Available services: $(all_services | tr '\n' ' ')"
    exit 1
  fi
}
```
To:
```sh
validate_service() {
  if [ -z "$(service_dir "$1")" ]; then
    log_error "Unknown service: $1"
    log_info "Available services: $(all_services | tr '\n' ' ')"
    exit 1
  fi
}
```

- [ ] **Step 5: Update render_templates() (line 87-97)**

Change:
```sh
render_templates() {
  _svc_dir="$SERVICES_DIR/$1"
```
To:
```sh
render_templates() {
  _svc_dir="$(service_dir "$1")"
```

- [ ] **Step 6: Update install_config_to_data() (lines 102-115)**

Change:
```sh
install_config_to_data() {
  _svc="$1"
  _svc_dir="$SERVICES_DIR/$_svc"
  _data="$SERVICES_DATA_DIR/$_svc"
```
To:
```sh
install_config_to_data() {
  _svc="$1"
  _svc_dir="$(service_dir "$_svc")"
  _data="$SERVICES_DATA_DIR/$_svc"
```

- [ ] **Step 7: Update install_caddy_route() (lines 118-125)**

Change:
```sh
install_caddy_route() {
  _svc="$1"
  _snippet="$SERVICES_DIR/$_svc/caddy.snippet.tmpl"
```
To:
```sh
install_caddy_route() {
  _svc="$1"
  _snippet="$(service_dir "$_svc")/caddy.snippet.tmpl"
```

- [ ] **Step 8: Update reload_caddy() (lines 137-142)**

Change:
```sh
reload_caddy() {
  if docker compose -f "$SERVICES_DIR/caddy/docker-compose.yml" ps --status running 2>/dev/null | grep -q caddy; then
    docker compose -f "$SERVICES_DIR/caddy/docker-compose.yml" exec caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || true
```
To:
```sh
reload_caddy() {
  _caddy_dir="$(service_dir caddy)"
  if docker compose -f "$_caddy_dir/docker-compose.yml" ps --status running 2>/dev/null | grep -q caddy; then
    docker compose -f "$_caddy_dir/docker-compose.yml" exec caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || true
```

- [ ] **Step 9: Update is_running() (lines 145-149)**

Change:
```sh
is_running() {
  _svc_dir="$SERVICES_DIR/$1"
```
To:
```sh
is_running() {
  _svc_dir="$(service_dir "$1")"
```

- [ ] **Step 10: Update do_init() (lines 174-186)**

Change:
```sh
  if [ -f "$SERVICES_DIR/$_svc/init.sh" ]; then
    sh "$SERVICES_DIR/$_svc/init.sh" "$SERVICES_DIR/$_svc"
  fi
```
To:
```sh
  _svc_dir="$(service_dir "$_svc")"
  if [ -f "$_svc_dir/init.sh" ]; then
    sh "$_svc_dir/init.sh" "$_svc_dir"
  fi
```

- [ ] **Step 11: Update do_start() (lines 188-206)**

Change:
```sh
  docker compose -f "$SERVICES_DIR/$_svc/docker-compose.yml" up -d
  if [ -f "$SERVICES_DIR/$_svc/post-start.sh" ]; then
    sh "$SERVICES_DIR/$_svc/post-start.sh" "$SERVICES_DIR/$_svc"
  fi
```
To:
```sh
  _svc_dir="$(service_dir "$_svc")"
  docker compose -f "$_svc_dir/docker-compose.yml" up -d
  if [ -f "$_svc_dir/post-start.sh" ]; then
    sh "$_svc_dir/post-start.sh" "$_svc_dir"
  fi
```

- [ ] **Step 12: Update do_stop() (lines 208-222)**

Change:
```sh
  if [ -f "$SERVICES_DIR/$_svc/docker-compose.yml" ]; then
    docker compose -f "$SERVICES_DIR/$_svc/docker-compose.yml" down
```
To:
```sh
  _svc_dir="$(service_dir "$_svc")"
  if [ -f "$_svc_dir/docker-compose.yml" ]; then
    docker compose -f "$_svc_dir/docker-compose.yml" down
```

- [ ] **Step 13: Update do_status() (lines 229-238)**

Change:
```sh
do_status() {
  _svc="$1"
  validate_service "$_svc"
  log_header "Status: $_svc"
  if [ -f "$SERVICES_DIR/$_svc/docker-compose.yml" ]; then
    docker compose -f "$SERVICES_DIR/$_svc/docker-compose.yml" ps
```
To:
```sh
do_status() {
  _svc="$1"
  validate_service "$_svc"
  log_header "Status: $_svc"
  _svc_dir="$(service_dir "$_svc")"
  if [ -f "$_svc_dir/docker-compose.yml" ]; then
    docker compose -f "$_svc_dir/docker-compose.yml" ps
```

- [ ] **Step 14: Verify no remaining direct SERVICES_DIR/$_svc references**

Run: `grep -n 'SERVICES_DIR/\$' profiles/homelab/mac/ops/scripts/services.sh`

Expected: Only the `CADDY_ROUTES_DIR` assignment line and the `service_dir` function's loop should remain. No `$SERVICES_DIR/$_svc` or `$SERVICES_DIR/$1` patterns.

- [ ] **Step 15: Run shellcheck**

Run: `shellcheck profiles/homelab/mac/ops/scripts/services.sh`

Expected: No new warnings (existing warnings are acceptable).

- [ ] **Step 16: Commit**

```bash
git add profiles/homelab/mac/ops/scripts/services.sh
git commit -m "refactor(homelab): update services.sh for two-level discovery

Add service_dir() helper for category-aware path resolution.
Update all functions to use it instead of flat SERVICES_DIR paths."
```

---

### Task 3: Upgrade Docker image versions

**Files:**
- Modify: `profiles/homelab/mac/ops/services/network/adguard_home/docker-compose.yml.tmpl`
- Modify: `profiles/homelab/mac/ops/services/monitoring/portainer/docker-compose.yml.tmpl`
- Modify: `profiles/homelab/mac/ops/services/monitoring/uptime_kuma/docker-compose.yml.tmpl`

- [ ] **Step 1: Upgrade AdGuard Home v0.107.73 -> v0.107.74**

In `profiles/homelab/mac/ops/services/network/adguard_home/docker-compose.yml.tmpl`, change:
```yaml
    image: adguard/adguardhome:v0.107.73
```
To:
```yaml
    image: adguard/adguardhome:v0.107.74
```

- [ ] **Step 2: Upgrade Portainer CE 2.21.5 -> 2.39.1 with trusted-origins**

In `profiles/homelab/mac/ops/services/monitoring/portainer/docker-compose.yml.tmpl`, change:
```yaml
    image: portainer/portainer-ce:2.21.5
    container_name: portainer
    restart: unless-stopped
    command: -H unix:///var/run/docker.sock --http-enabled
```
To:
```yaml
    image: portainer/portainer-ce:2.39.1
    container_name: portainer
    restart: unless-stopped
    command: -H unix:///var/run/docker.sock --http-enabled --trusted-origins https://containers.${LAB_DOMAIN}
```

- [ ] **Step 3: Upgrade Uptime Kuma 1.23.17 -> 2.2.1**

In `profiles/homelab/mac/ops/services/monitoring/uptime_kuma/docker-compose.yml.tmpl`, change:
```yaml
    image: louislam/uptime-kuma:1.23.17
```
To:
```yaml
    image: louislam/uptime-kuma:2.2.1
```

- [ ] **Step 4: Verify all image versions**

Run: `grep -r 'image:' profiles/homelab/mac/ops/services/ --include='*.tmpl' | sort`

Expected:
```
.../monitoring/grafana/docker-compose.yml.tmpl:    image: grafana/grafana-oss:13.0.0
.../monitoring/portainer/docker-compose.yml.tmpl:    image: portainer/portainer-ce:2.39.1
.../monitoring/prometheus/docker-compose.yml.tmpl:    image: prom/prometheus:v3.11.2
.../monitoring/uptime_kuma/docker-compose.yml.tmpl:    image: louislam/uptime-kuma:2.2.1
.../network/adguard_home/docker-compose.yml.tmpl:    image: adguard/adguardhome:v0.107.74
.../network/caddy/docker-compose.yml.tmpl:    image: caddy:2.11.2-alpine
```

- [ ] **Step 5: Commit**

```bash
git add profiles/homelab/mac/ops/services/network/adguard_home/docker-compose.yml.tmpl \
        profiles/homelab/mac/ops/services/monitoring/portainer/docker-compose.yml.tmpl \
        profiles/homelab/mac/ops/services/monitoring/uptime_kuma/docker-compose.yml.tmpl
git commit -m "feat(homelab): upgrade adguard, portainer, uptime-kuma

- AdGuard Home v0.107.73 -> v0.107.74 (patch)
- Portainer CE 2.21.5 -> 2.39.1 LTS (add --trusted-origins for CSRF)
- Uptime Kuma 1.23.17 -> 2.2.1 (major, auto-migrates DB on startup)"
```

---

### Task 4: Add Grafana dashboard tags

**Files:**
- Modify: `profiles/homelab/mac/ops/services/monitoring/grafana/provisioning/dashboards/caddy-monitoring.json`
- Modify: `profiles/homelab/mac/ops/services/monitoring/grafana/provisioning/dashboards/node-exporter-full.json`
- Modify: `profiles/homelab/mac/ops/services/monitoring/grafana/provisioning/dashboards/prometheus-stats.json`

- [ ] **Step 1: Tag caddy-monitoring.json**

In `caddy-monitoring.json` at line 2179 (top-level tags), change:
```json
  "tags": [],
```
To:
```json
  "tags": ["network", "caddy"],
```

- [ ] **Step 2: Tag node-exporter-full.json**

In `node-exporter-full.json` at line 827 (top-level tags, between `"style": "dark"` and `"templating"`), change:
```json
  "tags": [],
```
To:
```json
  "tags": ["monitoring", "host"],
```

Do NOT change the nested `"tags": []` at line 859 (inside a template variable definition).

- [ ] **Step 3: Tag prometheus-stats.json**

In `prometheus-stats.json` at line 1352 (top-level tags, between `"style": "dark"` and `"templating"`), change:
```json
  "tags": [
    "prometheus"
  ],
```
To:
```json
  "tags": ["monitoring", "prometheus"],
```

Do NOT change the nested `"tags": []` at lines 77 and 86 (inside annotation links).

- [ ] **Step 4: Verify tags**

Run: `grep -n '"tags"' profiles/homelab/mac/ops/services/monitoring/grafana/provisioning/dashboards/*.json`

Confirm the top-level tags are set correctly and nested tags are untouched.

- [ ] **Step 5: Commit**

```bash
git add profiles/homelab/mac/ops/services/monitoring/grafana/provisioning/dashboards/
git commit -m "feat(homelab): add category and service tags to grafana dashboards

caddy-monitoring: [network, caddy]
node-exporter-full: [monitoring, host]
prometheus-stats: [monitoring, prometheus]"
```

---

### Task 5: Update root README

**Files:**
- Modify: `/README.md`

- [ ] **Step 1: Update opening line and add table of contents**

Change the opening section (lines 1-16):
```markdown
# 🏠 dotfiles

[![verify](https://github.com/bkov96/dotfiles/actions/workflows/verify.yml/badge.svg)](https://github.com/bkov96/dotfiles/actions/workflows/verify.yml)
[![test](https://github.com/bkov96/dotfiles/actions/workflows/test.yml/badge.svg)](https://github.com/bkov96/dotfiles/actions/workflows/test.yml)

Personal machine configuration, organized by profile and platform. Dotfiles are symlinked into `$HOME`, with template files rendered using `envsubst` to inject personal values like name and email.

## Contents

- [Structure](#-structure)
- [Commands](#-commands)
- [Bootstrap a new machine](#-bootstrap-a-new-machine)
- [Customizing paths](#️-customizing-paths)
- [Bitwarden secrets](#-using-bitwarden-for-secrets)
- [Forking](#-forking)
- [What's next](#-whats-next)
```

To:
```markdown
# 🏠 dotfiles

[![verify](https://github.com/bkov96/dotfiles/actions/workflows/verify.yml/badge.svg)](https://github.com/bkov96/dotfiles/actions/workflows/verify.yml)
[![test](https://github.com/bkov96/dotfiles/actions/workflows/test.yml/badge.svg)](https://github.com/bkov96/dotfiles/actions/workflows/test.yml)

Machine configuration manager, organized by profile and platform. Dotfiles are symlinked into `$HOME`, with template files rendered using `envsubst` to inject personal values like name and email.

## Contents

- [Structure](#-structure)
- [Profiles & Platforms](#-profiles--platforms)
- [Commands](#-commands)
- [Bootstrap a new machine](#-bootstrap-a-new-machine)
- [Customizing paths](#️-customizing-paths)
- [Bitwarden secrets](#-using-bitwarden-for-secrets)
- [Forking](#-forking)
```

- [ ] **Step 2: Update structure tree**

Change the structure tree (lines 20-33) to reflect category directories:
```markdown
```
profiles/
  <profile>/
    <platform>/
      [<user>/]             # optional per-user directory (when DOTFILES_USER is set)
        dotfiles/           # config files to be linked/rendered into $HOME
        scripts/
          init.sh           # sets up the platform and creates .config.json from example
          install.sh        # installs all dependencies (e.g. brew bundle)
          capture.sh        # captures installed packages back to the repo
          upgrade.sh        # upgrades all packages (e.g. brew upgrade)
        services/           # Docker service definitions (homelab ops only)
          <category>/       # e.g. network/, monitoring/
            <service>/      # contains docker-compose.yml.tmpl + optional hooks
        .config.example.json
        Brewfile            # platform-specific packages (macOS)
```
```

- [ ] **Step 3: Add Profiles & Platforms section**

Insert after the `---` that follows the "How it works" section (after line 45), before the Commands section:

```markdown
## 🖥 Profiles & Platforms

| Profile | Platform | Description |
| ------- | -------- | ----------- |
| `work` | `mac` | Work machine |
| `homelab` | `mac` | Homelab server ([bootstrap guide](profiles/homelab/mac/README.md), [services](profiles/homelab/mac/ops/services/README.md)) |
| `github` | `ci` | CI environment |

The homelab profile has two users: `admin` (bootstrap, sudo) and `ops` (day-to-day operations, services).

---
```

- [ ] **Step 4: Add Services command group**

Insert a Services table after the Repo table (after line 82) and before the Standalone section:

```markdown
### Services (homelab ops only)

| Command                | Description                                    |
| ---------------------- | ---------------------------------------------- |
| `services list`        | Show all services and their status              |
| `services init [name]` | Initialize all or a specific service            |
| `services start [name]`| Start all or a specific service (ordered)       |
| `services stop [name]` | Stop all or a specific service (reverse order)  |
| `services restart name`| Restart a specific service                      |
| `services status [name]`| Show detailed container status                 |
```

- [ ] **Step 5: Remove the "What's next" section**

Delete the entire section (lines 172-177):
```markdown
## 🔭 What's next

See [docs/homelab.md](docs/homelab.md) for guidelines on expanding this repo into a homelab setup with multi-user environments and Docker-based services.
```

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: update root README with profiles, services, and new framing

Reframe as machine configuration manager. Add profiles & platforms
section, services command group. Update structure tree for category
directories. Remove outdated What's next section."
```

---

### Task 6: Add table of contents to homelab bootstrap README

**Files:**
- Modify: `profiles/homelab/mac/README.md`

- [ ] **Step 1: Add table of contents after the title**

Insert after line 1 (`# Homelab Mac Mini Bootstrap`), before line 3 (`Bootstrap a fresh...`):

```markdown

## Contents

- [Prerequisites](#prerequisites)
- [Phase 1: Admin Bootstrap](#phase-1-admin-bootstrap-at-desk-with-display)
- [Relocation](#relocation)
- [Phase 2: Ops Setup](#phase-2-ops-setup-via-ssh-from-workmac)
- [Maintenance](#maintenance)
- [macOS version](#macos-version)
```

- [ ] **Step 2: Commit**

```bash
git add profiles/homelab/mac/README.md
git commit -m "docs(homelab): add table of contents to bootstrap README"
```

---

### Task 7: Update services README

**Files:**
- Modify: `profiles/homelab/mac/ops/services/README.md`

- [ ] **Step 1: Add table of contents after the title**

Insert after line 1 (`# Homelab Services`), before line 3 (`Docker-based services...`):

```markdown

## Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Commands](#commands)
- [Service lifecycle](#service-lifecycle)
- [Adding a new service](#adding-a-new-service)
- [Startup order](#startup-order)
- [Data persistence](#data-persistence)
- [Manual setup steps](#manual-setup-steps-not-repo-managed)
- [Gotchas worth knowing](#gotchas-worth-knowing)
- [Future work](#future-work-intentionally-not-implemented)
```

- [ ] **Step 2: Update architecture diagram**

Replace the architecture diagram (lines 7-28) with a version that groups services by category:

```markdown
```
                    DNS (port 53)          HTTPS (port 443)
                        │                       │
               ┌────────┴────────┐     ┌────────┴────────┐
               │  network/       │     │  network/       │
               │  AdGuard Home   │     │  Caddy (proxy)  │
               └─────────────────┘     └────────┬────────┘
                                                │
                                        caddy_proxy network
                                  ┌─────────────┼─────────────┐
                                  │             │             │
                           ┌──────┴──────┐ ┌────┴─────┐ ┌─────┴──────┐
                           │ monitoring/ │ │monitoring/│ │monitoring/ │
                           │ Uptime Kuma │ │ Portainer│ │  Grafana   │
                           └─────────────┘ └──────────┘ └─────┬──────┘
                                                              │ queries
                                                       ┌──────┴──────┐
                                                       │ monitoring/ │
                                                       │ Prometheus  │◄── scrapes
                                                       └─────────────┘    host metrics
```
```

- [ ] **Step 3: Update "Adding a new service" section**

Change step 1 (line 96):
```markdown
1. Create a directory under `services/` named after the product (e.g., `grafana/`)
```
To:
```markdown
1. Create a directory under `services/<category>/` named after the product (e.g., `monitoring/grafana/`)
```

- [ ] **Step 4: Update minimal service example paths**

Change the example header (line 104):
```markdown
**`my_service/docker-compose.yml.tmpl`**
```
To:
```markdown
**`monitoring/my_service/docker-compose.yml.tmpl`**
```

Change the caddy snippet example header (line 122):
```markdown
**`my_service/caddy.snippet.tmpl`**
```
To:
```markdown
**`monitoring/my_service/caddy.snippet.tmpl`**
```

- [ ] **Step 5: Fix dashboard list in Grafana first-run section**

In section 9 (Grafana first-run login, around line 249), change:
```markdown
`admin` with the password set in `GRAFANA_ADMIN_PASSWORD`. The four
provisioned dashboards (Node Exporter Full, Docker Monitoring,
Prometheus 2.0 Stats, Caddy Monitoring) appear under the "Homelab"
```
To:
```markdown
`admin` with the password set in `GRAFANA_ADMIN_PASSWORD`. The three
provisioned dashboards (Node Exporter Full, Prometheus Stats,
Caddy Monitoring) appear under the "Homelab"
```

- [ ] **Step 6: Review and update Future work section**

The "Future work" section (lines 280-290) references three deferred items. Keep all three -- they are still listed in the monitoring design spec and are intentionally deferred. No changes needed unless the user says otherwise.

- [ ] **Step 7: Commit**

```bash
git add profiles/homelab/mac/ops/services/README.md
git commit -m "docs(homelab): update services README for category directories

Add table of contents. Update architecture diagram, adding-a-service
instructions, and example paths for category layout. Fix dashboard
count in Grafana first-run section."
```

---

### Task 8: Delete docs/homelab.md

**Files:**
- Delete: `docs/homelab.md`

- [ ] **Step 1: Delete the file**

```bash
git rm docs/homelab.md
```

- [ ] **Step 2: Verify no remaining references**

Run: `grep -r 'homelab\.md' README.md docs/`

Expected: No matches (the root README link was already removed in Task 5).

- [ ] **Step 3: Commit**

```bash
git commit -m "docs: remove outdated docs/homelab.md

Content is either superseded by the services README or no longer
accurate (abstract naming convention was not adopted)."
```

---

### Task 9: Final verification

- [ ] **Step 1: Run shellcheck on services.sh**

Run: `shellcheck profiles/homelab/mac/ops/scripts/services.sh`

Expected: No new errors.

- [ ] **Step 2: Run the repo's format and verify checks**

Run: `make scripts-verify DOTFILES_PROFILE=github DOTFILES_PLATFORM=ci`

Expected: All checks pass.

- [ ] **Step 3: Verify no broken internal links in READMEs**

Run: `grep -rn '\[.*\](.*\.md' README.md profiles/homelab/mac/README.md profiles/homelab/mac/ops/services/README.md`

For each link found, verify the target file exists.

- [ ] **Step 4: Verify service discovery glob works**

Run a quick shell check that the two-level glob finds all 6 services:
```bash
SERVICES_DIR=profiles/homelab/mac/ops/services
for dir in "$SERVICES_DIR"/*/*/; do
  [ -f "$dir/docker-compose.yml.tmpl" ] && basename "$dir"
done | sort
```

Expected:
```
adguard_home
caddy
grafana
portainer
prometheus
uptime_kuma
```
