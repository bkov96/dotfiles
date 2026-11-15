# ☸️ Kubernetes / Azure

Work-only additions on top of the shared [Terminal](../../shared/terminal.md) setup. Installed via `profiles/work/mac/Brewfile`: `kubernetes-cli`, `kubectx`, `k9s`, `helm`, `kubelogin`, `azure-cli`, `carapace`.

## ⌨️ Commands

| Command      | Does                                                |
| ------------ | --------------------------------------------------- |
| `kc`         | `kubectl`                                           |
| `kcx`        | `kubectx` — switch cluster (fuzzy)                  |
| `kcn`        | `kubens` — switch namespace (fuzzy)                 |
| `k9` / `k9s` | Cluster TUI: `l` logs, `s` shell, `:pods`, `:deploy` |

## ✨ Completions

**carapace** supplies rich completions for `kubectl`, `az`, `helm` and others, falling back to normal zsh completions. `kubectl` uses its native completion instead (sourced after carapace), so `kc logs <Tab>` offers live pod names.

## 🧭 Prompt context

The prompt shows `☸ <context> (<namespace>)` when the *current directory* contains a `chart`, `charts`, `helm`, `k8s`, `kubernetes`, `manifests` or `deploy` folder, or a `Chart.yaml`, `kustomization.yaml`, `skaffold.yaml` or `Tiltfile`. Contexts matching `prod` show in **bold red**. Change the triggers via `detect_files` / `detect_folders` in `~/.config/starship.toml`.

## 🎨 k9s skin

A transparent skin at `~/.config/k9s/skins/ghostty.yaml` follows the terminal theme. It is selected by seeding `~/.config/k9s/config.yaml` on the first `configs link`; k9s owns that file afterwards.
