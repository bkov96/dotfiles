# 📚 Documentation

## 🧭 General

Applies to every profile.

| Doc                                       | Contents                                                        |
| ----------------------------------------- | --------------------------------------------------------------- |
| [Bootstrap](general/bootstrap.md)         | Set up any new macOS machine from a clean install               |
| [Commands](general/commands.md)           | Every `dotfiles <group> <action>` command                       |
| [Configuration](general/configuration.md) | Repo structure, `.config.json`, templates, Bitwarden secrets    |
| [Forking](general/forking.md)             | Use this repo as the base for your own machines                 |

## 🔗 Shared

Applies to some profiles.

| Doc                              | Contents                                                       |
| -------------------------------- | -------------------------------------------------------------- |
| [Terminal](shared/terminal.md)   | Ghostty, the zsh layer, CLI tools, keybinds (work, personal)   |

## 🖥 Profiles

Each profile has a `setup.md` with the full step-by-step; the other docs are reference.

### 💼 work/mac

| Doc                                       | Contents                                             |
| ----------------------------------------- | ---------------------------------------------------- |
| [Setup](profiles/work/setup.md)           | Step-by-step setup of the work Mac                   |
| [Kubernetes](profiles/work/kubernetes.md) | kubectl/k9s shortcuts, completions, prompt context   |

### 🧑‍💻 personal/mac

| Doc                                       | Contents                                    |
| ----------------------------------------- | ------------------------------------------- |
| [Setup](profiles/personal/setup.md)       | Setup of the personal Mac (.NET + Expo dev) |

### 🏠 homelab/mac

| Doc                                              | Contents                                                          |
| ------------------------------------------------ | ----------------------------------------------------------------- |
| [Setup](profiles/homelab/setup.md)               | Step-by-step rebuild: admin phase, relocation, ops phase, services |
| [Services](profiles/homelab/services.md)         | Architecture, lifecycle, adding a service, gotchas                |
| [Manual setup](profiles/homelab/manual-setup.md) | One-time steps the repo can't do (DNS, CA trust, first logins, power-loss recovery) |
| [Media](profiles/homelab/media.md)               | Media stack: first-launch config, quality profiles, maintenance   |
| [Monitoring](profiles/homelab/monitoring.md)     | Exporters and the Uptime Kuma inventory + restore                 |
