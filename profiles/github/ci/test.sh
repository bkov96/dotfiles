#!/bin/sh

REPO_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
PROFILE_DIR="profiles/github/ci"
DOTFILES_DIR="$PROFILE_DIR/dotfiles"

cd "$REPO_DIR" || exit 1

# shellcheck source=/dev/null
. "$REPO_DIR/lib/log.sh"

TEST_HOME="$(mktemp -d)"
HOME="$TEST_HOME"
export HOME

PASS=0
FAIL=0

ok() {
  PASS=$((PASS + 1))
  log_ok "$1"
}
ko() {
  FAIL=$((FAIL + 1))
  log_fail "$1"
}

assert_contains() {
  if grep -q "$1" "$2"; then ok "$3"; else ko "$3"; fi
}

assert_not_contains() {
  if ! grep -q "$1" "$2"; then ok "$3"; else ko "$3"; fi
}

assert_symlink() {
  if [ -L "$1" ]; then ok "$2"; else ko "$2"; fi
}

assert_regular_file() {
  if [ -f "$1" ] && [ ! -L "$1" ]; then ok "$2"; else ko "$2"; fi
}

assert_not_exists() {
  if [ ! -e "$1" ] && [ ! -L "$1" ]; then ok "$2"; else ko "$2"; fi
}

assert_no_diff() {
  if diff -q "$1" "$2" >/dev/null 2>&1; then ok "$3"; else
    ko "$3"
    diff "$1" "$2" || true
  fi
}

assert_has_diff() {
  if ! diff -q "$1" "$2" >/dev/null 2>&1; then ok "$3"; else ko "$3"; fi
}

# Setup: copy example files to gitignored runtime files
cp "$PROFILE_DIR/.config.example.json" "$PROFILE_DIR/.config.json"

# Save original template
TMPL="$REPO_DIR/$DOTFILES_DIR/.testconfig.tmpl"
TMPL_BAK="$(mktemp)"
cp "$TMPL" "$TMPL_BAK"

# ---------------------------------------------------------------
log_header "Test: link"

sh lib/link.sh "$PROFILE_DIR" "$DOTFILES_DIR"

assert_contains "TestUser" "$TEST_HOME/.testconfig" "link: template renders name"
assert_contains "test@example.com" "$TEST_HOME/.testconfig" "link: template renders email"
assert_not_contains "\${TEST_NAME}" "$TEST_HOME/.testconfig" "link: name placeholder substituted"
assert_not_contains "\${TEST_EMAIL}" "$TEST_HOME/.testconfig" "link: email placeholder substituted"
assert_symlink "$TEST_HOME/.testrc" "link: .testrc is a symlink"

# ---------------------------------------------------------------
log_header "Test: link (template dest replaces stale symlink)"

# Simulate switching a dotfile from symlink mode to template mode: the
# destination still holds a stale symlink pointing into the repo. Rendering
# must replace the symlink, not write through it into the repo.
STRAY="$REPO_DIR/$DOTFILES_DIR/.testconfig"
rm -f "$TEST_HOME/.testconfig"
ln -s "$STRAY" "$TEST_HOME/.testconfig"

sh lib/link.sh "$PROFILE_DIR" "$DOTFILES_DIR"

assert_regular_file "$TEST_HOME/.testconfig" "link: stale symlink replaced by rendered file"
assert_contains "TestUser" "$TEST_HOME/.testconfig" "link: rendered file has substituted content"
assert_not_exists "$STRAY" "link: no rendered file leaked into repo"
rm -f "$STRAY"

# ---------------------------------------------------------------
log_header "Test: gather (round-trip idempotency)"

sh lib/gather.sh "$PROFILE_DIR" "$DOTFILES_DIR"

assert_no_diff "$TMPL_BAK" "$TMPL" "gather: round-trip leaves template unchanged"

# Reset and re-link for next test
cp "$TMPL_BAK" "$TMPL"
sh lib/link.sh "$PROFILE_DIR" "$DOTFILES_DIR"

# ---------------------------------------------------------------
log_header "Test: gather (modified file)"

echo "org=MyOrg" >>"$TEST_HOME/.testconfig"

sh lib/gather.sh "$PROFILE_DIR" "$DOTFILES_DIR"

assert_has_diff "$TMPL_BAK" "$TMPL" "gather: modification produces a diff"
assert_contains "org=MyOrg" "$TMPL" "gather: new line captured in template"
assert_contains "\${TEST_NAME}" "$TMPL" "gather: name placeholder preserved"
assert_contains "\${TEST_EMAIL}" "$TMPL" "gather: email placeholder preserved"

log_header "Template diff"
diff "$TMPL_BAK" "$TMPL" || true

# ---------------------------------------------------------------
log_header "Test: bw:// auto-unlock on expired session"

# Restore template and write a config with bw:// references
cp "$TMPL_BAK" "$TMPL"
printf '{"env":{"TEST_NAME":"bw://TEST_NAME"},"paths":{".testconfig.tmpl":"~/.testconfig"}}\n' >"$PROFILE_DIR/.config.json"
unset BW_SESSION
rm -f .bw_session

# Create a mock bw that simulates a locked vault and fails to unlock
MOCK_BIN="$(mktemp -d)"
cat >"$MOCK_BIN/bw" <<'MOCK'
#!/bin/sh
if [ "$1" = "status" ]; then printf '{"status":"locked"}'; exit 0; fi
echo "mock bw: unlock failed" >&2
exit 1
MOCK
chmod +x "$MOCK_BIN/bw"
OLD_PATH="$PATH"
export PATH="$MOCK_BIN:$PATH"

output=$(sh lib/link.sh "$PROFILE_DIR" "$DOTFILES_DIR" 2>&1 || true)
if echo "$output" | grep -q "re-authenticating"; then
  ok "bw: expired session triggers re-authentication"
else
  ko "bw: expired session triggers re-authentication"
fi

export PATH="$OLD_PATH"
rm -rf "$MOCK_BIN"

# Restore config from example for cleanup
cp "$PROFILE_DIR/.config.example.json" "$PROFILE_DIR/.config.json"

# ---------------------------------------------------------------
# Cleanup
cp "$TMPL_BAK" "$TMPL"
rm -f "$TMPL_BAK"
rm -f "$PROFILE_DIR/.config.json"
rm -rf "$TEST_HOME"

printf '\n'
if [ "$FAIL" -eq 0 ]; then
  printf '%s%s✅  Results: %d passed, %d failed%s\n' "$_LOG_BOLD" "$_LOG_GREEN" "$PASS" "$FAIL" "$_LOG_RESET"
else
  printf '%s%s❌  Results: %d passed, %d failed%s\n' "$_LOG_BOLD" "$_LOG_RED" "$PASS" "$FAIL" "$_LOG_RESET"
fi
[ "$FAIL" -eq 0 ]
