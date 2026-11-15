# 🔧 Homelab manual setup

One-time steps the repo can't do for you. The order to run them in is in [Setup, phase 3](setup.md#-phase-3-services).

| #  | Step                                   | When                        |
| -- | -------------------------------------- | --------------------------- |
| 1  | UniFi wildcard DNS records             | Before starting services    |
| 2  | Trust Caddy's root CA                  | After Caddy's first start   |
| 3  | Uptime Kuma admin user                 | After first start           |
| 4  | Portainer admin user                   | Within 5 min of first start |
| 5  | Native node_exporter                   | Before starting services    |
| 6  | Native macmon                          | Before starting services    |
| 7  | Telegram monitoring bot                | Before starting services    |
| 8  | Grafana first login                    | After first start           |
| 9  | FileBrowser Quantum admin              | After first start           |
| 10 | Auto-recovery after power loss         | Any time                    |

The media stack has its own guide: [Media: first-launch setup](media.md#-first-launch-setup).

## 1. UniFi: wildcard DNS records

Add two wildcard records on the UniFi router, both pointing to the homelab IP:

- `*.${LAB_DOMAIN}`
- `*.media.${LAB_DOMAIN}`

## 2. Trust Caddy's root CA

Caddy generates its own root CA on first start. Trust it on each device to avoid browser warnings.

```sh
# On the homelab: extract the cert
ssh ops@homelab '~/.orbstack/bin/docker cp caddy:/data/caddy/pki/authorities/local/root.crt ~/caddy-root-ca.crt'

# On your Mac: fetch it
scp ops@homelab:/Users/ops/caddy-root-ca.crt ~/Downloads/
```

- **macOS:** double-click the `.crt` → Keychain Access → **System** keychain → find "Caddy Local Authority" → double-click → Trust → **Always Trust**.
- **iOS:** AirDrop the `.crt` → Settings → Profile Downloaded → Install → Settings → General → About → Certificate Trust Settings → toggle on.
- **The Mac Mini itself:** do it over Screen Sharing. `security add-trusted-cert` refuses to run in a non-interactive SSH session.

## 3. Uptime Kuma

Visit `https://uptime.${LAB_DOMAIN}` and create the admin user. Monitors live in its SQLite DB, not the repo; recreate them from the [monitor inventory](monitoring.md#-uptime-kuma-inventory).

## 4. Portainer

Visit `https://containers.${LAB_DOMAIN}` and create the admin user **within 5 minutes** of container start. Missed the window? `dfs services restart portainer`.

The local OrbStack environment appears automatically through the mounted `/var/run/docker.sock`.

## 5. Native node_exporter

Runs natively because Linux containers can't see macOS host metrics. Installed by `make ops-install`; start it once:

```sh
brew services start node_exporter
curl -s http://127.0.0.1:9100/metrics | head -5    # expect "# HELP …" lines
```

Listens on `127.0.0.1:9100`; Prometheus scrapes it at `host.docker.internal:9100`.

## 6. Native macmon

Apple Silicon power, temperature and CPU/GPU metrics via private IOKit APIs, so also native. Installed by `make ops-install`; register it once:

```sh
macmon serve --port 9190 --interval 1000 --install
curl -s http://127.0.0.1:9190/metrics | head -5    # expect "# HELP macmon_…" lines
```

This installs a launchd agent that starts on login and serves `127.0.0.1:9190`; Prometheus scrapes it at `host.docker.internal:9190`. Uninstall: `macmon serve --uninstall`.

## 7. Telegram monitoring bot

Grafana alerts use a **dedicated** bot, separate from the Uptime Kuma one, so metric alerts stay apart from reachability pings.

1. In Telegram, message `@BotFather`, send `/newbot`, follow the prompts (e.g. name it `homelab-monitoring`). Save the token to Bitwarden as `TELEGRAM_BOT_TOKEN_MONITORING`.
2. Open a chat with the new bot and send any message (e.g. `/start`).
3. Fetch the chat ID and save `chat.id` to Bitwarden as `TELEGRAM_CHAT_ID_MONITORING`:

   ```sh
   curl "https://api.telegram.org/bot<TOKEN>/getUpdates"
   ```

## 8. Grafana

Visit `https://monitoring.${LAB_DOMAIN}`, log in as `admin` with `GRAFANA_ADMIN_PASSWORD`. No wizard: dashboards are provisioned into the **Homelab** folder, alert rules and the Telegram contact point under **Alerting**.

**Smoke-test alerting:** temporarily edit a rule to a threshold you currently exceed (e.g. HostHighCPU to `1`). A Telegram message should arrive within ~1 minute. Restore the threshold.

## 9. FileBrowser Quantum

Visit `https://files.${LAB_DOMAIN}`, log in with `admin` / `admin`, then immediately:

1. Change the admin password (Settings → Profile Management)
2. Enable TOTP 2FA (Settings → Profile Management → Two-Factor Authentication)

Registration is disabled; create further users in the admin UI.

## 10. Auto-recovery after power loss

Four layers must all be in place for the homelab to return unattended. Only the last is repo-managed.

| Layer                    | Setting                                                                                              | Verify                                         |
| ------------------------ | ---------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| Hardware power-on        | `sudo pmset -a autorestart 1`                                                                        | `pmset -g \| grep autorestart` → `autorestart 1` |
| User session             | System Settings → Users & Groups → Automatically log in as → `ops`. Needs FileVault **off**          | `fdesetup status`                              |
| OrbStack auto-start      | OrbStack → Settings → System → **Start OrbStack at login**; or add `OrbStack.app` under System Settings → General → Login Items | reboot test below    |
| Container restart policy | `restart: unless-stopped` in every compose template — already set                                   | —                                              |

After a reboot, from your laptop:

```sh
ssh ops@homelab '~/.orbstack/bin/docker ps'
```

It should list running containers. "Cannot connect to the Docker daemon" means OrbStack didn't start — re-check the login item. Expect all Uptime Kuma monitors green 1–2 minutes after power returns.
