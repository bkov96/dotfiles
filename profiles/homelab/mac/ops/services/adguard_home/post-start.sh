#!/bin/sh
set -e

# Post-start hook for AdGuard Home.
# Adds wildcard DNS rewrite via API because AdGuard Home strips rewrites
# from the config file on first-run setup.
# Idempotent: the API returns an error if the rewrite already exists,
# which we silently ignore.

_LIB_DIR="$(
  cd "$(dirname "$0")" || exit
  pwd
)"
while [ ! -f "$_LIB_DIR/lib/log.sh" ] && [ "$_LIB_DIR" != "/" ]; do
  _LIB_DIR="$(dirname "$_LIB_DIR")"
done
# shellcheck source=/dev/null
. "$_LIB_DIR/lib/log.sh"

if [ -z "$LAB_DOMAIN" ] || [ -z "$HOMELAB_IP" ]; then
  log_error "LAB_DOMAIN or HOMELAB_IP not set"
  exit 1
fi

if [ -z "$LOCAL_DNS_FORWARDER" ] || [ -z "$UPSTREAM_DNS_1" ] || [ -z "$UPSTREAM_DNS_2" ]; then
  log_error "LOCAL_DNS_FORWARDER, UPSTREAM_DNS_1, or UPSTREAM_DNS_2 not set"
  exit 1
fi

# Wait for AdGuard Home API to be ready (up to 30 seconds)
_tries=0
while [ "$_tries" -lt 30 ]; do
  if docker exec adguard_home wget -q -O- http://127.0.0.1:3000/control/status >/dev/null 2>&1; then
    break
  fi
  _tries=$((_tries + 1))
  sleep 1
done

if [ "$_tries" -ge 30 ]; then
  log_error "AdGuard Home API did not become ready"
  exit 1
fi

# Add DNS rewrites (idempotent: API returns error for duplicates, ignored)
# - Wildcard "*.${LAB_DOMAIN}" matches subdomains (uptime, dns, etc.)
# - Exact "${LAB_DOMAIN}" matches the bare domain itself (wildcard does not)
add_rewrite() {
  _domain="$1"
  _payload="{\"domain\":\"${_domain}\",\"answer\":\"${HOMELAB_IP}\"}"
  if docker exec adguard_home wget -q -O- \
    --post-data="$_payload" \
    --header='Content-Type: application/json' \
    http://127.0.0.1:3000/control/rewrite/add >/dev/null 2>&1; then
    log_item "Added DNS rewrite: ${_domain} -> ${HOMELAB_IP}"
  else
    log_item "DNS rewrite already present: ${_domain}"
  fi
}

add_rewrite "*.${LAB_DOMAIN}"
add_rewrite "${LAB_DOMAIN}"

# Configure upstream DNS:
# - "[/internal/]${LOCAL_DNS_FORWARDER}": *.internal queries forwarded to UniFi
#   so non-lab local DNS records (e.g., printer.internal) keep resolving
# - Public DNS for everything else
# The full upstream list is set via API to ensure idempotent application even
# if AdGuard Home rewrites its YAML on schema migration.
_upstream_payload=$(printf '{"upstream_dns":["[/internal/]%s","%s","%s"]}' \
  "$LOCAL_DNS_FORWARDER" "$UPSTREAM_DNS_1" "$UPSTREAM_DNS_2")
if docker exec adguard_home wget -q -O- \
  --post-data="$_upstream_payload" \
  --header='Content-Type: application/json' \
  http://127.0.0.1:3000/control/dns_config >/dev/null 2>&1; then
  log_item "Configured upstream DNS (with conditional forwarding for *.internal)"
else
  log_warn "Failed to configure upstream DNS via API"
fi
