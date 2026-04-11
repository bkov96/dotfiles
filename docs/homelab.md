# Homelab

Guidelines for expanding this repo into a macOS home server setup.

## Current state

The homelab runs on an M4 Mac Mini (macOS Tahoe 26.4.1) with two users:

- **admin** — bootstrap only, has sudo. Used for initial setup and future system-level changes via SSH.
- **ops** — day-to-day operator, no sudo. Runs services, manages configs, has Bitwarden access.

The machine runs headless with Ethernet, SSH (key-only), and Screen Sharing (VNC) for ops. See [profiles/homelab/mac/README.md](../profiles/homelab/mac/README.md) for the full bootstrap runbook.

## Future: Service management

The next phase adds containerized services via OrbStack. The planned structure:

```
profiles/homelab/mac/
  services/                   # one subdirectory per service group (abstract names)
    media/
      docker-compose.tmpl
    dns/
      docker-compose.tmpl
    network/
      docker-compose.tmpl
```

Service directory names are intentionally abstract. The actual software being used is specified only in `.config.json` and Bitwarden — not in the directory structure or committed files.

All specifics — image versions, port bindings, volume paths, credentials — are template variables resolved at deploy time via `dotfiles configs link`.

## Future: Per-service users

Each service may eventually run under its own least-privilege macOS system user, created via setup scripts under `setup/admin/`. This is not yet implemented — all services currently run under ops.

## Keeping the repo public

With all specifics templated via Bitwarden, the repo is safe to keep public. What's in the repository:

- Abstract directory structure (service categories, not product names)
- Template placeholders like `${MEDIA_PORT}` (no actual values)
- Setup script logic (user creation, permission patterns)

What never enters the repository (lives only in `.config.json` and Bitwarden):

| Category | Examples |
| -------- | -------- |
| Software identities | image names, versions, app names |
| Network | ports, hostnames, internal IPs |
| Credentials | tokens, passwords, API keys |
| Users | system usernames, UIDs |
| Paths | data directories, mount points |

---

Back to [README](../README.md)
