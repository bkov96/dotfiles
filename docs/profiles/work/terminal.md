# 👻 Terminal

The work Mac uses [Ghostty](https://ghostty.org). Ghostty is only a terminal emulator: fast rendering, tabs, splits, themes, keybinds. Autosuggestions, history search, completions and AI come from the **zsh layer** wired up in `.zshrc`.

To install it all, follow [Setup](setup.md).

## 📦 What's installed

From `profiles/work/mac/Brewfile`:

| Package                         | Purpose                                 |
| ------------------------------- | --------------------------------------- |
| `ghostty`                       | The terminal                            |
| `font-jetbrains-mono-nerd-font` | Font with the glyphs the prompt needs   |
| `starship`                      | Prompt                                  |
| `atuin`                         | History search                          |
| `zsh-autosuggestions`           | Inline suggestions                      |
| `zsh-fast-syntax-highlighting`  | Command coloring                        |
| `fzf` + `fzf-tab`               | Fuzzy pickers and Tab menus             |
| `eza`, `bat`, `zoxide`, `fd`, `ripgrep`, `delta` | Modern CLI tools       |
| `carapace`, `kubectx`, `k9s`    | Kubernetes / Azure completions and tools |
| `claude-code`                   | AI                                      |

## 🎨 Ghostty config

`~/.config/ghostty/config` is a symlink to `dotfiles/.ghostty_config`. Reload with **⌘⇧,** — no restart needed.

```
font-family = JetBrainsMono Nerd Font   # must be a Nerd Font for prompt glyphs
font-size = 15
theme = Desert
cursor-style = block
mouse-hide-while-typing = true
window-padding-x = 8
window-padding-y = 8
macos-option-as-alt = true              # ⌥ sends Alt (word jumps, some CLIs)
shell-integration-features = ssh-env,ssh-terminfo
window-save-state = always              # needs the macOS toggle in Setup step 6
```

**Changing the theme:** browse with the command below (type to filter, `q` to quit), then set `theme =` to the exact name it prints. A "theme not found" dialog on launch means the name is wrong.

```sh
/Applications/Ghostty.app/Contents/MacOS/ghostty +list-themes
```

## ⌨️ Keybinds

Ghostty defaults:

| Keys               | Action                                   |
| ------------------ | ---------------------------------------- |
| `⌘T` / `⌘N`        | New tab / window                         |
| `⌃Tab` / `⌃⇧Tab`   | Next / previous tab                      |
| `⌘D` / `⌘⇧D`       | Split right / down                       |
| `⌘[` / `⌘]`        | Focus previous / next split              |
| `⌘⌥←↑↓→`           | Focus split in that direction            |
| `⌘⇧↵`              | Zoom the focused split                   |
| `⌘↑` / `⌘↓`        | Jump to previous / next prompt           |
| `⌘K`               | Clear screen                             |
| `⌘⇧,`              | Reload config                            |

Shell:

| Keys                          | Action                                               |
| ----------------------------- | ---------------------------------------------------- |
| `→` or `End`                  | Accept the grey autosuggestion                       |
| `Ctrl-R`                      | Atuin history search (Enter inserts, doesn't run)    |
| `Ctrl-G`                      | Turn the typed description into a command via Claude |
| `Ctrl-T`                      | Fuzzy-pick a file, insert its path                   |
| `Alt-C`                       | Fuzzy-pick a subdirectory and `cd` into it           |
| `Tab`                         | Searchable completion menu (fzf-tab)                 |
| `Opt+←` / `Opt+→`             | Move by word                                         |
| `Opt+⌫`                       | Delete previous word                                 |
| `Shift+←` / `Shift+→`         | Select by character                                  |
| `Shift+Opt+←` / `Shift+Opt+→` | Select by word                                       |
| `Shift+Home` / `Shift+End`    | Select to start / end of line                        |

Selection works on the command line only (scrollback is mouse-driven). It comes from a vendored MIT widget, [jirutka/zsh-shift-select](https://github.com/jirutka/zsh-shift-select), at `~/.config/zsh/shift-select.zsh`.

## ✨ The zsh layer

Wired at the end of `dotfiles/.zshrc.tmpl`. The order there is intentional.

- **Starship prompt** — path, git branch and status, duration of commands over 2s. Config: `~/.config/starship.toml`.
- **Autosuggestions** — the rest of a matching previous command appears in grey as you type.
- **Syntax highlighting** — valid commands turn green, unknown ones red, before you hit Enter.
- **Atuin** — `Ctrl-R` fuzzy history. `↑` still walks plain history (`--disable-up-arrow`). History is local only; to sync later: `atuin register` / `atuin login`, then `atuin sync`. Config: `~/.config/atuin/config.toml`.
- **AI** — run `claude` for agentic work, or type plain English and press `Ctrl-G` to get a command. `Ctrl-G` uses Haiku (~1–3s), never auto-runs, strips code fences, and keeps your text if the call fails. Both use the Claude Code login, no API key.
- **Completions** — `compinit -u` (the `-u` skips Homebrew's "insecure directories" prompt). **carapace** supplies rich completions for `kubectl`, `az`, `helm` and others, falling back to normal zsh completions.

## 🛠 CLI tools

| Command                   | Tool    | What it does                                                    |
| ------------------------- | ------- | --------------------------------------------------------------- |
| `ls` / `ll` / `la`        | eza     | Listing with icons and colors; `ll`/`la` add a git-status column |
| `cat <file>`              | bat     | Syntax highlighting and line numbers                            |
| `z <dir>`                 | zoxide  | Jump to a visited directory by partial name; `cd` still works   |
| `fd <name>`               | fd      | Find files by name                                              |
| `rg <pattern>`            | ripgrep | Search file contents                                            |
| `git diff` / `git log -p` | delta   | Colored, line-numbered diffs; `n`/`N` jump between files. CLI only |

Remove a tool's Brewfile line and alias, then re-link, to undo it.

## 🔐 SSH

Ghostty advertises `TERM=xterm-ghostty`; hosts without that terminfo mis-render (broken backspace and arrows). `shell-integration-features = ssh-env,ssh-terminfo` fixes it:

- `ssh-terminfo` installs the terminfo on the remote at first login (needs `infocmp`/`tic` there), then caches it.
- `ssh-env` falls back to `xterm-256color` if that fails.

Inspect which hosts have it: `ghostty +ssh-cache`.

## ☸️ Kubernetes / Azure

| Command      | Does                                                |
| ------------ | --------------------------------------------------- |
| `kc`         | `kubectl`                                           |
| `kcx`        | `kubectx` — switch cluster (fuzzy)                  |
| `kcn`        | `kubens` — switch namespace (fuzzy)                 |
| `k9` / `k9s` | Cluster TUI: `l` logs, `s` shell, `:pods`, `:deploy` |

**Prompt context:** the prompt shows `☸ <context> (<namespace>)` when the *current directory* contains a `chart`, `charts`, `helm`, `k8s`, `kubernetes`, `manifests` or `deploy` folder, or a `Chart.yaml`, `kustomization.yaml`, `skaffold.yaml` or `Tiltfile`. Contexts matching `prod` show in **bold red**. Change the triggers via `detect_files` / `detect_folders` in `~/.config/starship.toml`.

**k9s skin:** a transparent skin at `~/.config/k9s/skins/ghostty.yaml` follows the terminal theme. It is selected by seeding `~/.config/k9s/config.yaml` on the first `configs link`; k9s owns that file afterwards.

## 🔄 Applying changes

| Changed                                             | To apply                                           |
| --------------------------------------------------- | -------------------------------------------------- |
| `.ghostty_config`, `.starship.toml`, `.atuin.toml`  | Nothing — symlinks. Reload Ghostty (`⌘⇧,`) or open a new window |
| `.zshrc.tmpl`                                       | `dfs configs link`, then `exec zsh`                |
| `Brewfile`                                          | `dfs packages install`                             |
