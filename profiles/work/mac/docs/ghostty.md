# 👻 Ghostty terminal setup

This machine uses [Ghostty](https://ghostty.org) as its terminal, replacing Warp.

The important mental model: **Ghostty is only a terminal emulator** — it draws
text fast (GPU-accelerated) and handles windows, tabs, splits, themes, and
keybinds. It deliberately does *not* build in autosuggestions, completions, or
AI. Those "smart" Warp-like features come from the **zsh layer** (Homebrew
plugins + a few tools), wired up in `.zshrc`. So this doc covers two halves:

1. **Ghostty itself** — appearance + keybinds
2. **The zsh layer** — the Warp-replacement features

Everything is reproducible from this repo — no manual clicking. See
[How it's wired](#-how-its-wired) at the bottom.

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
font-size = 16
theme = Catppuccin Mocha                # any of ~460 built-in themes
cursor-style = block
mouse-hide-while-typing = true          # hide the pointer while typing
window-padding-x = 8                    # breathing room, in px
window-padding-y = 8
macos-option-as-alt = true              # ⌥ sends Alt (needed for some CLIs / word-jumps)
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

Everything flows through this repo's standard machinery — no manual setup.

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
renders everything). Done.
