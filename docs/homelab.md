# 🏡 Homelab

Guidelines for expanding this repo into a macOS home server setup with multi-user environments, Docker-based services, and zero secrets in the repository.

## Contents

1. [Overview](#1-overview)
2. [Profile structure](#2-profile-structure)
3. [Multi-user setup](#3-multi-user-setup)
4. [Service management with Docker](#4-service-management-with-docker)
5. [Keeping the repo public](#5-keeping-the-repo-public)
6. [Extending link.sh for system paths](#6-extending-linksh-for-system-paths)

---

## 1. Overview

The `homelab/mac` profile follows the same admin-centric model as `work/mac`, with one key difference: a single admin account owns and runs the repo, and is responsible for deploying configuration for multiple system users and services.

All machine-specific values — port numbers, hostnames, credentials, software versions, system usernames — live in `.config.json` and are resolved from Bitwarden at deploy time. Nothing in the repo itself reveals what services you run or how they're configured.

---

## 2. Profile structure

The `homelab/mac` profile extends the standard layout with a `services/` directory and per-user setup scripts:

```
profiles/homelab/mac/
  .config.example.json        # all env vars as bw:// references
  Brewfile                    # docker, cli tools, etc.
  dotfiles/                   # admin user's shell config
    .zshrc
  services/                   # one subdirectory per service group (abstract names)
    media/
      docker-compose.tmpl
    dns/
      docker-compose.tmpl
    network/
      docker-compose.tmpl
  setup/
    init.sh                   # install Xcode CLT, Homebrew, create .config.json
    install.sh                # brew bundle
    users/
      media.sh                # create media service user, set permissions
      dns.sh                  # create dns service user, set permissions
      network.sh              # create network service user, set permissions
```

Service directory names are intentionally abstract (`media/`, `dns/`, `network/`). The actual software being used is specified only in `.config.json` and Bitwarden — not in the directory structure or committed files.

---

## 3. Multi-user setup

Each service runs under its own least-privilege macOS system user. The admin account creates and configures these users via setup scripts.

Example `setup/users/media.sh`:

```sh
#!/usr/bin/env bash

# Create a system user for the media service
dscl . -create /Users/media-svc
dscl . -create /Users/media-svc UserShell /usr/bin/false
dscl . -create /Users/media-svc UniqueID 501   # <- should come from .config.json
dscl . -create /Users/media-svc PrimaryGroupID 20

# Create service directory and restrict ownership
mkdir -p /opt/services/media
chown media-svc /opt/services/media
chmod 700 /opt/services/media
```

All UID values, group IDs, and usernames are templated — the script above would use `${MEDIA_SVC_UID}`, resolved from `.config.json` / Bitwarden.

The admin user runs each setup script once during initial machine provisioning:

```sh
bash profiles/homelab/mac/setup/users/media.sh
bash profiles/homelab/mac/setup/users/dns.sh
bash profiles/homelab/mac/setup/users/network.sh
```

---

## 4. Service management with Docker

Each service group has a `docker-compose.tmpl` file. All specifics — image versions, port bindings, volume paths, credentials — are template variables resolved at deploy time.

Example `services/media/docker-compose.tmpl`:

```yaml
services:
  media-server:
    image: ${MEDIA_IMAGE}:${MEDIA_VERSION}
    container_name: media-server
    ports:
      - "${MEDIA_PORT}:${MEDIA_INTERNAL_PORT}"
    volumes:
      - ${MEDIA_DATA_PATH}:/data
    environment:
      - PLEX_CLAIM=${MEDIA_CLAIM_TOKEN}
    restart: unless-stopped
```

The corresponding `.config.example.json` entry:

```json
{
  "env": {
    "MEDIA_IMAGE": "bw://MEDIA_IMAGE",
    "MEDIA_VERSION": "bw://MEDIA_VERSION",
    "MEDIA_PORT": "bw://MEDIA_PORT",
    "MEDIA_INTERNAL_PORT": "bw://MEDIA_INTERNAL_PORT",
    "MEDIA_DATA_PATH": "bw://MEDIA_DATA_PATH",
    "MEDIA_CLAIM_TOKEN": "bw://MEDIA_CLAIM_TOKEN"
  },
  "paths": {
    "services/media/docker-compose.tmpl": "/opt/services/media/docker-compose.yml"
  }
}
```

After `make link`, the rendered `docker-compose.yml` lands in `/opt/services/media/` ready to run:

```sh
docker compose -f /opt/services/media/docker-compose.yml up -d
```

Starting and stopping services is left to the admin — either manually or via a launchd daemon that calls `docker compose up` on boot.

---

## 5. Keeping the repo public

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

> 💡 If a value would help an attacker narrow their target, it belongs in Bitwarden — not in the repo. When in doubt, template it.

---

## 6. Extending `link.sh` for system paths

The current `link.sh` deploys everything relative to `$HOME`. For homelab services, rendered files need to land in system paths like `/opt/services/media/docker-compose.yml`. The `.config.json` `paths` section already supports absolute destinations — this works today:

```json
{
  "paths": {
    "services/media/docker-compose.tmpl": "/opt/services/media/docker-compose.yml"
  }
}
```

The rendered file is written to the absolute path, not linked. Two things to keep in mind:

- The target directory must exist and be writable by the user running `make link`
- If the file needs to be owned by a service user (e.g. `media-svc`), a `chown` call in the setup script handles that after the first deploy

---

Back to [README](../README.md)
