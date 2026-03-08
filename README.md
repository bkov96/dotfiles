# 🏠 dotfiles

Personal machine configuration, organized by environment and platform. Dotfiles are symlinked into `$HOME`, with template files rendered using `envsubst` to inject personal values like name and email.

## 📁 Structure

```
environments/
  <env>/
    <platform>/
      dotfiles/             # config files to be linked/rendered into $HOME
      .env.example          # required environment variables (copy to .env and fill in)
      .config.example.json  # optional path overrides (copy to .config.json to customize)
      ...                   # platform-specific files (e.g. Brewfile on macOS)
```

Currently available environments: `work/mac`, `homelab/mac`.

### How it works

- **Plain dotfiles** (e.g. `.zshrc`) are symlinked directly into `$HOME`
- **Template files** (e.g. `.gitconfig.tmpl`) are rendered with `envsubst` using variables from `.env`, and written to `$HOME` (without the `.tmpl` suffix)
- By default all files land in `$HOME`. Override individual destinations via `.config.json`

> 💡 **No reverse sync needed for symlinked files.** Because plain dotfiles are symlinks, any edits you make directly on the machine (e.g. tweaking `.zshrc`) are instantly reflected in this repo — just `git add` and commit as usual. Note: template files (`.tmpl`) are rendered as copies, so edits to e.g. `~/.gitconfig` on the machine won't sync back — edit the `.tmpl` source in the repo instead.

---

## 🚀 Bootstrap a new machine on macOS

### 1. Install Xcode Command Line Tools

This gives you `git` and basic build tools:

```sh
xcode-select --install
```

### 2. Install Homebrew

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the post-install instructions to add Homebrew to your `PATH`.

### 3. Clone this repo

```sh
git clone https://github.com/bkov/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
```

### 4. Install packages

Pick your environment (e.g. `work/mac`) and install everything via Homebrew:

```sh
brew bundle --file environments/work/mac/Brewfile
```

### 5. Create your `.env`

```sh
cp environments/work/mac/.env.example environments/work/mac/.env
```

Open `.env` and fill in your values:

```sh
GIT_CONFIG_NAME=Jane Doe
GIT_CONFIG_EMAIL=jane@example.com
```

### 6. Link dotfiles

```sh
make link
```

For a different environment or platform:

```sh
make link ENV=homelab PLATFORM=mac
```

That's it — your dotfiles are live. 🎉

---

## ⚙️ Customizing paths

By default every file in `dotfiles/` lands in `$HOME`. To put a file somewhere else, create a `.config.json` from the example:

```sh
cp environments/<env>/<platform>/.config.example.json environments/<env>/<platform>/.config.json
```

Then override only the paths you care about — everything else is still auto-discovered:

```json
{
  "paths": {
    ".gitconfig.tmpl": "~/.gitconfig",
    ".zshrc": "/some/other/path/.zshrc"
  }
}
```

Both `.env` and `.config.json` are gitignored and never committed.
