# 👻 Ghostty terminal setup

This machine uses [Ghostty](https://ghostty.org) as its terminal, replacing Warp.

The important mental model: **Ghostty is only a terminal emulator** — it draws
text fast (GPU-accelerated) and handles windows, tabs, splits, themes, and
keybinds. It deliberately does *not* build in autosuggestions, completions, or
AI. Those "smart" Warp-like features come from the **zsh layer** (Homebrew
plugins + a few tools), wired up in `.zshrc`. So this doc covers two halves:

1. **Ghostty itself** — appearance + keybinds
2. **The zsh layer** — the Warp-replacement features

Almost everything is reproducible from this repo; a few one-time macOS toggles
are listed under [Manual steps on a new machine](#manual-steps-on-a-new-machine).
See [How it's wired](#-how-its-wired) near the bottom.

---

## 📦 What's installed

All added to `profiles/work/mac/Brewfile`:

| Package | Purpose |
| --- | --- |
| `cask "ghostty"` | The terminal |
| `cask "font-jetbrains-mono-nerd-font"` | Coding font incl. the glyphs the prompt needs |
| `brew "starship"` | Prompt |
| `brew "atuin"` | History search |
| `brew "zsh-autosuggestions"` | Inline suggestions |
| `brew "zsh-fast-syntax-highlighting"` | Command coloring |

`claude` (AI) is already present via `cask "claude-code@latest"`.

---

## 🎨 Ghostty appearance

Config lives at `~/.config/ghostty/config` (symlinked from
`dotfiles/.ghostty_config`). Each setting:

```
font-family = JetBrainsMono Nerd Font   # must be a Nerd Font for prompt glyphs
font-size = 15
theme = Desert                          # any of ~460 built-in themes (browse: +list-themes)
cursor-style = block
mouse-hide-while-typing = true          # hide the pointer while typing
window-padding-x = 8                    # breathing room, in px
window-padding-y = 8
macos-option-as-alt = true              # ⌥ sends Alt (needed for some CLIs / word-jumps)
shell-integration-features = ssh-env,ssh-terminfo   # SSH terminfo fix (see SSH section)
window-save-state = always              # restore tabs/splits on relaunch (see Manual steps)
```

### Changing the theme

Your `~/.config/ghostty/config` is a **symlink into this repo**, so editing it
edits your dotfiles directly. To browse all themes live:

```sh
/Applications/Ghostty.app/Contents/MacOS/ghostty +list-themes
```

Arrow keys (or `j`/`k`) scroll, the right pane previews the palette, type to
filter, `q` to quit. It prints the exact name string to use. Then change the
`theme =` line and reload with **⌘⇧,** — no restart needed.

> ⚠️ Theme names are exact, capitalized, and sometimes spaced oddly, e.g.
> `Catppuccin Mocha`, `TokyoNight Storm`, `Dracula`, `Nord`. If Ghostty shows a
> "theme not found" dialog on launch, the string is wrong — check
> `+list-themes`.

---

## ⌨️ Useful Ghostty keybinds (macOS defaults)

These ship with Ghostty; no config needed. `⌘` = super, `⌃` = ctrl.

| Keys | Action |
| --- | --- |
| `⌘T` | New tab |
| `⌃Tab` / `⌃⇧Tab` | Next / previous tab |
| `⌘D` | Split right |
| `⌘⇧D` | Split down |
| `⌘[` / `⌘]` | Focus previous / next split |
| `⌘⌥←↑↓→` | Focus split in that direction |
| `⌘⇧↵` | Zoom the focused split (toggle fullscreen-in-pane) |
| `⌘N` | New window |
| `⌘K` | Clear screen |
| `⌘↑` / `⌘↓` | **Jump to previous / next prompt** (see shell integration) |
| `⌘⇧,` | Reload config |
| `⌘C` / `⌘V` | Copy / paste |

### Shell integration (automatic)

Ghostty auto-detects zsh and injects shell integration — no setup. The visible
payoff is **`⌘↑` / `⌘↓` to jump between prompts**: instead of scrolling, you hop
straight to the start of each previous command's output. Handy after a command
dumps a screenful.

---

## ✨ The zsh layer (Warp-replacement features)

All wired at the end of `.zshrc` (rendered from `dotfiles/.zshrc.tmpl`). Order
matters and is intentional.

### 1. Starship prompt

A fast, informative prompt showing path, git branch + status, and how long the
last command took. Config: `~/.config/starship.toml`.

```
dotfiles on  feat/ghostty [!?] took 3s
❯
```

- ` feat/ghostty` — current branch
- `[!?]` — git status (`!` modified, `?` untracked, etc.)
- `took 3s` — appears only when a command ran longer than 2s

### 2. Inline autosuggestions (`zsh-autosuggestions`)

As you type, the rest of a matching previous command appears in grey. This is
Warp's most-loved feature.

```
❯ git com                          ← you typed this
❯ git commit -m "wip"              ← grey = suggestion from history
```

Press **`→`** (right arrow) or `End` to accept, then edit or run it. Keep typing
to ignore it.

### 3. Syntax highlighting (`zsh-fast-syntax-highlighting`)

Commands are colored *as you type*, so you catch typos before hitting Enter:

```
❯ git status      ← "git" is GREEN (found on PATH → valid)
❯ gti status      ← "gti" is RED   (not a command → typo)
```

Also colors quotes, paths, options, and flags.

### 4. History search (`atuin`)

Press **`Ctrl-R`** for a full-screen fuzzy search over your shell history —
Warp's history, better. Type to filter; ↑/↓ to move; `Enter` to put the command
on your line (it does *not* auto-run, so you can edit first); `Esc` to cancel.

```
❯ (Ctrl-R)
> docker
  docker compose up -d          ~/repos/app        2h ago
  docker ps                     ~/repos/dotfiles   yesterday
  docker system prune -af       ~/repos/app        last week
```

Config: `~/.config/atuin/config.toml`. Notes:
- **`↑` is unchanged** — it still walks plain history; only `Ctrl-R` opens Atuin
  (we passed `--disable-up-arrow`).
- History is **local only** — no sync, no telemetry. To later sync (encrypted)
  across machines: `atuin register` / `atuin login` then `atuin sync`.

### 5. AI command generation

Two subscription-backed options (no API key, no metered billing — both use your
Claude Code login):

**a) Agentic — run `claude`.** For "I don't know the incantation, just do the
thing." It can read files, run commands, and iterate. Strictly more capable than
Warp AI.

**b) Inline `Ctrl-G` widget.** Type a plain-English description on the command
line and press **`Ctrl-G`**; it's replaced with a real command for you to eyeball
and run.

```
❯ list files over 100mb changed this week      ← type this, press Ctrl-G
❯ find . -type f -size +100M -mtime -7          ← replaced with the command
```

- Uses Haiku for speed; takes ~1–3s (you'll briefly see `… asking claude`).
- The command is **never auto-run** — you review it and press Enter yourself.
- If Claude errors or returns nothing, your typed text is preserved (not wiped).
- Markdown code fences in the model's output are stripped automatically.

### 6. Completions

`compinit -u` initializes zsh's completion system so `Tab` completion works
(the `-u` skips an interactive "insecure directories" prompt Homebrew can trigger
on first launch).

---

## 🔧 How it's wired

Almost everything flows through this repo's standard machinery; a few one-time
macOS toggles are listed under [Manual steps](#manual-steps-on-a-new-machine).

| File | Role |
| --- | --- |
| `profiles/work/mac/Brewfile` | Installs Ghostty, font, tools |
| `dotfiles/.ghostty_config` | → symlinked to `~/.config/ghostty/config` |
| `dotfiles/.starship.toml` | → `~/.config/starship.toml` |
| `dotfiles/.atuin.toml` | → `~/.config/atuin/config.toml` |
| `dotfiles/.zshrc.tmpl` | → rendered to `~/.zshrc` (the feature wiring + `Ctrl-G` widget) |
| `.config.example.json` `paths` | Registers where each file links to |

### Applying changes

- **`.ghostty_config`, `.starship.toml`, `.atuin.toml`** are *symlinks* — editing
  the file in `~/.config/...` edits the repo file directly, and it takes effect on
  the next reload (Ghostty: `⌘⇧,`; shell: new window). No sync step needed.
- **`.zshrc`** is a *rendered template* (it injects secrets), so changes to
  `dotfiles/.zshrc.tmpl` require a re-render:

  ```sh
  dfs configs link      # unlock Bitwarden if prompted; re-renders ~/.zshrc
  exec zsh              # or just open a new window
  ```

### Reproducing on a fresh machine

`dfs packages install` (installs the Brewfile) then `dfs configs link` (links +
renders everything) — then the one-time Manual steps below.

### Manual steps on a new machine

Things the repo can't set for you (macOS toggles / one-time actions):

- **Window restore:** macOS **System Settings → Desktop & Dock → "Close windows
  when quitting an application" must be OFF**, or `window-save-state = always`
  can't restore your tabs/splits on relaunch.
- **Default terminal:** macOS has no global "default terminal" setting for
  third-party apps — just use/pin Ghostty (some tools honor `$TERMINAL`).
- **SSH terminfo:** the first `ssh` to a host auto-installs Ghostty's terminfo
  there (cached after; needs `infocmp`/`tic` on the remote). Inspect with
  `ghostty +ssh-cache`.
- **Bitwarden:** `dfs configs link` needs Bitwarden unlocked to render secrets
  into `~/.zshrc` / `~/.gitconfig`.
- **k9s skin:** activated by seeding `~/.config/k9s/config.yaml` on the first
  `configs link` (automatic; k9s owns that file afterward).

---

## 🛠 Modern CLI tools

Classic commands, upgraded. Installed via the Brewfile; `ls`/`cat` are aliased,
`cd` is augmented with `z`, and git diffs render through delta.

| Command | Tool | What it does |
| --- | --- | --- |
| `ls` / `ll` / `la` | eza | File listing with icons, colors, and (for `ll`/`la`) a git-status column |
| `cat <file>` | bat | Prints a file with syntax highlighting + line numbers |
| `z <dir>` | zoxide | Jumps to a directory you've visited before, by partial name — e.g. `z dotfiles`. Plain `cd` still works. |
| `fd <name>` | fd | Finds files/dirs by name (fast, no arcane syntax) — e.g. `fd Brewfile` |
| `rg <pattern>` | ripgrep | Searches file *contents* fast — e.g. `rg "TODO"` |
| `git diff` / `git log -p` | delta | Colored, line-numbered diffs in the terminal. `n`/`N` jump between files. CLI only — Fork/GitLens are unaffected. |

Examples:

    $ ll
     src    README.md  M
     lib    Makefile

    $ z dot        # → jumps to ~/repos/dotfiles
    $ rg "brew \"" profiles/work/mac/Brewfile
    $ fd -e md profiles/work/mac    # all .md files under the profile

All are plain Homebrew binaries — remove a line and re-link to undo any of them.

---

## ⌨️ Line editing & selection

Command-line editing keys (these work on the current command line, not
scrollback — scrollback selection is still mouse-driven):

| Keys | Action |
| --- | --- |
| `Opt+←` / `Opt+→` | Move by word |
| `Opt+⌫` | Delete previous word |
| `Shift+←` / `Shift+→` | Select by character |
| `Shift+Opt+←` / `Shift+Opt+→` | Select by word |
| `Shift+Home` / `Shift+End` | Select to start / end of line |
| type / `⌫` / `Del` (with a selection) | Replace the selection |

Selection is provided by a vendored MIT widget
(`~/.config/zsh/shift-select.zsh`, from
[jirutka/zsh-shift-select](https://github.com/jirutka/zsh-shift-select)).

## 🔐 SSH

Ghostty advertises `TERM=xterm-ghostty`. Remote hosts that don't have that
terminfo entry will mis-render your shell (ghost characters, broken backspace
and arrows). The config enables Ghostty's built-in fix:

    shell-integration-features = ssh-env,ssh-terminfo

- `ssh-terminfo` installs Ghostty's terminfo on the remote (via `infocmp`/`tic`)
  on first login, then caches it so later logins are instant.
- `ssh-env` sets `TERM`, falling back to `xterm-256color` if terminfo install fails.

Inspect/manage which hosts got the terminfo with `ghostty +ssh-cache`.

---

## 🔎 Fuzzy finding (fzf + fzf-tab)

[fzf](https://github.com/junegunn/fzf) is a fuzzy picker: type a few letters
from anywhere in a name to filter a list, arrow to a match, Enter to pick.

| Keys | Action |
| --- | --- |
| `Ctrl-T` | Fuzzy-pick a file; the path is inserted at the cursor |
| `Alt-C` | Fuzzy-pick a subdirectory and `cd` into it |
| `Ctrl-R` | Unchanged — still Atuin history (fzf's own Ctrl-R is overridden) |

`fzf-tab` upgrades the **Tab** key into a searchable menu:

    git checkout <Tab>   → searchable list of branches
    cd <Tab>             → searchable dir list, with a folder preview (via eza)
    git add <Tab>        → searchable list of changed files

Type to filter, arrows to move, Enter to accept, Esc to cancel.

---

## ☸ Kubernetes / Azure

When the **current directory** contains a Kubernetes marker — a `chart`/`charts`/
`helm`/`k8s`/`kubernetes`/`manifests`/`deploy` folder, or a `Chart.yaml`/
`kustomization.yaml`/`skaffold.yaml`/`Tiltfile` file — the prompt shows your
current cluster + namespace: `☸ <context> (<namespace>)`. Any context whose name
matches `prod` is shown in **bold red** as a wrong-cluster safeguard.

> Starship checks the current directory's own contents (not the whole repo tree),
> so it shows at a repo root that holds a `chart/` folder and inside that folder,
> but not in unrelated source subdirectories. Adjust the triggers via
> `detect_files`/`detect_folders` in `~/.config/starship.toml`.

| Command | Does |
| --- | --- |
| `kc` | alias for `kubectl` |
| `kcx` | alias for `kubectx` — switch cluster (fuzzy list via fzf) |
| `kcn` | alias for `kubens` — switch namespace (fuzzy list via fzf) |

Completions follow the aliases automatically (zsh expands them before
completing), so `kc get <Tab>`, `az <Tab>`, `helm <Tab>` all give rich,
searchable menus via **carapace** + fzf-tab. carapace uses a `zsh` bridge, so
any command it doesn't natively cover falls back to your normal completions.

### k9s — terminal cluster dashboard

Run `k9` (or `k9s`) for an interactive TUI over the current cluster: browse pods,
tail logs (`l`), shell in (`s`), delete, describe, switch resources with `:pods`
/ `:deploy` etc. Its colors follow your terminal theme (transparent skin at
`~/.config/k9s/skins/ghostty.yaml`).
