# Exporters

Prometheus exporters for the media stack. Each container polls its
target service's HTTP API and exposes Prometheus metrics on the
shared `metrics_internal` Docker network.

## Services

| Container             | Image                                                            | Target              | Secret env             |
| --------------------- | ---------------------------------------------------------------- | ------------------- | ---------------------- |
| `exportarr-sonarr`    | `ghcr.io/onedr0p/exportarr:v2.3.0`                               | `sonarr:8989`       | `SONARR_API_KEY`       |
| `exportarr-radarr`    | `ghcr.io/onedr0p/exportarr:v2.3.0`                               | `radarr:7878`       | `RADARR_API_KEY`       |
| `exportarr-prowlarr`  | `ghcr.io/onedr0p/exportarr:v2.3.0`                               | `prowlarr:9696`     | `PROWLARR_API_KEY`     |
| `exportarr-bazarr`    | `ghcr.io/onedr0p/exportarr:v2.3.0`                               | `bazarr:6767`       | `BAZARR_API_KEY`       |
| `exportarr-lidarr`    | `ghcr.io/onedr0p/exportarr:v2.3.0`                               | `lidarr:8686`       | `LIDARR_API_KEY`       |
| `qbittorrent-exporter`| `ghcr.io/esanchezm/prometheus-qbittorrent-exporter:sha-3e55078`  | `qbittorrent:8080`  | `QBITTORRENT_PASSWORD` |
| `jellyfin-exporter`   | `rebelcore/jellyfin-exporter:v1.5.0` (Docker Hub)                | `jellyfin:8096`     | `JELLYFIN_API_KEY`     |
| `seerr-exporter`      | `ghcr.io/opspotes/jellyseerr-exporter:1.4.0` (amd64 only)        | `seerr:5055`        | `SEERR_API_KEY`        |

Lifecycle: managed as a single Compose project via
`dfs services {init,start,stop,restart,status} exporters`.

## Notes on individual exporters

- **`exportarr` (Sonarr/Radarr/Lidarr/Prowlarr/Bazarr)** — single image,
  one container per *Arr; the *Arr name is passed as the `command`. The
  `ENABLE_ADDITIONAL_METRICS` flag is on for Sonarr, Radarr and Lidarr; on
  Lidarr it adds a per-artist fan-out, so that job alone is scraped every
  60s instead of the global 15s.
- **`qbittorrent-exporter`** — no semver tags upstream; pinned to a
  specific `sha-<short>` tag. Bump intentionally.
- **`jellyfin-exporter`** — published on Docker Hub (not GHCR). Newer
  versions changed env var names from `JELLYFIN_BASEURL`/`APIKEY` to
  `JELLYFIN_ADDRESS`/`JELLYFIN_TOKEN`.
- **`seerr-exporter`** — published as `opspotes/jellyseerr-exporter`
  (a fork of `WillFantom/overseerr-exporter`). The container reads
  `JELLYSEERR_*` env vars and emits `jellyseerr_*` metrics — those
  names are baked into the binary. Image is amd64-only; runs on
  Apple Silicon via Rosetta (`platform: linux/amd64`).
- **`QBITTORRENT_PASSWORD`** was previously stored in Bitwarden for
  reference only. Adding qBittorrent scraping promoted it to an
  active env var.

## API key generation

Capture each key from the target service's UI, store it in the
`dotfiles/homelab/mac` Bitwarden item under the matching field name
(see "Secret env" column above), then re-render `.config.json`:

```bash
cd profiles/homelab/mac/ops
dotfiles configs unlock
dotfiles configs link
dfs services restart exporters
```

| Service                                      | UI path                                                                                                 |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Sonarr / Radarr / Lidarr / Prowlarr / Bazarr | Settings → General → API Key                                                                            |
| Jellyfin                                     | Dashboard → API Keys → New (name: `exporter`)                                                           |
| Seerr                                        | Settings → General → API Key                                                                            |
| qBittorrent                                  | Use the admin password (already in Bitwarden)                                                           |
| Navidrome                                    | No UI — you choose the value; store as `NAVIDROME_METRICS_PASSWORD` (compose: `ND_PROMETHEUS_PASSWORD`) |

## Verifying

New or changed Prometheus scrape jobs need a restart to take effect:
`docker compose up -d` is a no-op when the compose file itself hasn't
changed, and `prometheus.yml` is a bind-mounted file, so re-rendering it
via `dfs services start` alone doesn't reload it.

```bash
dfs services restart prometheus
```

```bash
# All scrape targets healthy (run from the prometheus container —
# port 9090 is not published on the host).
docker exec prometheus wget -qO- http://localhost:9090/api/v1/targets \
  | jq '[.data.activeTargets[] | select(.health!="up") | .labels.job]'

# Direct metrics check from inside the prometheus container.
docker exec prometheus wget -qO- http://exportarr-sonarr:9707/metrics | grep '^sonarr_'
```

The four media-stack dashboards land in the **Homelab** folder of
Grafana automatically: `Media Dashboard` (Sonarr/Radarr/Lidarr/Prowlarr),
`qBittorrent`, `Jellyfin`, `Seerr`.
