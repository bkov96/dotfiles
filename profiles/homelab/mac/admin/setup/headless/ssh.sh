#!/bin/sh
set -e

PROFILE_DIR="$1"

# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../../../lib/log.sh"
# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../../../lib/resolve.sh"

log_header "Configuring SSH..."

BW_ITEM="dotfiles/$DOTFILES_PROFILE/$DOTFILES_PLATFORM"
SSHD_CONFIG="/etc/ssh/sshd_config"

if has_bw_refs "$PROFILE_DIR/.config.json"; then
  ensure_bw_session
  fetch_bw_item "$BW_ITEM"
fi

OPS_USER=$(resolve_value "$(jq -r '.env.OPS_USER' "$PROFILE_DIR/.config.json")")
SSH_PUBLIC_KEY_B64=$(resolve_value "$(jq -r '.env.SSH_PUBLIC_KEY_B64' "$PROFILE_DIR/.config.json")")
SSH_PUBLIC_KEY=$(printf '%s' "$SSH_PUBLIC_KEY_B64" | base64 -d)
ADMIN_USER=$(whoami)

# Enable Remote Login (SSH)
# Note: systemsetup requires Full Disk Access on macOS Tahoe,
# so we check if sshd is listening on port 22 instead.
if nc -z localhost 22 2>/dev/null; then
  log_skip "Remote Login already enabled (port 22 listening)"
else
  log_header "Manual step required: Enable Remote Login"
  log_info "Open System Settings > General > Sharing > Remote Login"
  log_info "Toggle Remote Login ON"
  log_warn "systemsetup requires Full Disk Access on macOS Tahoe — use the GUI instead"
  printf "\n   Press Enter once Remote Login is enabled..."
  read -r _

  if nc -z localhost 22 2>/dev/null; then
    log_ok "Remote Login enabled"
  else
    log_error "Remote Login is still off — port 22 not listening"
    exit 1
  fi
fi

# Restrict SSH to admin and ops via access group
if dseditgroup -o checkmember -m "$OPS_USER" com.apple.access_ssh >/dev/null 2>&1; then
  log_skip "User '$OPS_USER' already in SSH access group"
else
  log_info "Adding '$OPS_USER' to SSH access group..."
  sudo dseditgroup -o create -q com.apple.access_ssh 2>/dev/null || true
  sudo dseditgroup -o edit -a "$OPS_USER" -t user com.apple.access_ssh
  log_ok "Added '$OPS_USER' to SSH access group"
fi

if dseditgroup -o checkmember -m "$ADMIN_USER" com.apple.access_ssh >/dev/null 2>&1; then
  log_skip "User '$ADMIN_USER' already in SSH access group"
else
  log_info "Adding '$ADMIN_USER' to SSH access group..."
  sudo dseditgroup -o edit -a "$ADMIN_USER" -t user com.apple.access_ssh
  log_ok "Added '$ADMIN_USER' to SSH access group"
fi

# Configure sshd_config for key-only auth
SSHD_BACKUP="${SSHD_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
if grep -q "^PasswordAuthentication no" "$SSHD_CONFIG" 2>/dev/null; then
  log_skip "sshd_config already configured for key-only auth"
else
  log_info "Backing up sshd_config to $SSHD_BACKUP..."
  sudo cp "$SSHD_CONFIG" "$SSHD_BACKUP"

  log_info "Configuring sshd_config for key-only auth..."
  sudo tee "$SSHD_CONFIG" >/dev/null <<SSHD_EOF
# Managed by dotfiles homelab bootstrap
# Backup at: $SSHD_BACKUP

PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

AllowUsers $ADMIN_USER $OPS_USER

# Subsystem for sftp
Subsystem sftp /usr/libexec/sftp-server
SSHD_EOF
  log_ok "sshd_config configured"
fi

# Deploy authorized keys for ops
OPS_SSH_DIR="/Users/$OPS_USER/.ssh"
OPS_AUTH_KEYS="$OPS_SSH_DIR/authorized_keys"
if [ -f "$OPS_AUTH_KEYS" ] && grep -qF "$SSH_PUBLIC_KEY" "$OPS_AUTH_KEYS" 2>/dev/null; then
  log_skip "Authorized key already deployed for '$OPS_USER'"
else
  log_info "Deploying authorized key for '$OPS_USER'..."
  sudo mkdir -p "$OPS_SSH_DIR"
  printf '%s\n' "$SSH_PUBLIC_KEY" | sudo tee -a "$OPS_AUTH_KEYS" >/dev/null
  sudo chown -R "$OPS_USER" "$OPS_SSH_DIR"
  sudo chmod 700 "$OPS_SSH_DIR"
  sudo chmod 600 "$OPS_AUTH_KEYS"
  log_ok "Authorized key deployed for '$OPS_USER'"
fi

# Deploy authorized keys for admin
ADMIN_SSH_DIR="/Users/$ADMIN_USER/.ssh"
ADMIN_AUTH_KEYS="$ADMIN_SSH_DIR/authorized_keys"
if [ -f "$ADMIN_AUTH_KEYS" ] && grep -qF "$SSH_PUBLIC_KEY" "$ADMIN_AUTH_KEYS" 2>/dev/null; then
  log_skip "Authorized key already deployed for '$ADMIN_USER'"
else
  log_info "Deploying authorized key for '$ADMIN_USER'..."
  mkdir -p "$ADMIN_SSH_DIR"
  printf '%s\n' "$SSH_PUBLIC_KEY" >>"$ADMIN_AUTH_KEYS"
  chmod 700 "$ADMIN_SSH_DIR"
  chmod 600 "$ADMIN_AUTH_KEYS"
  log_ok "Authorized key deployed for '$ADMIN_USER'"
fi

# Restart SSH daemon
log_info "Restarting SSH daemon..."
sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
log_ok "SSH daemon restarted"

log_done
