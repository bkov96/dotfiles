#!/bin/sh
set -e

# Post-start hook for Caddy.
# Exports the auto-generated root CA to a shared location so other
# services (e.g., Uptime Kuma) can mount it and trust Caddy's certs.

_LIB_DIR="$(
  cd "$(dirname "$0")" || exit
  pwd
)"
while [ ! -f "$_LIB_DIR/lib/log.sh" ] && [ "$_LIB_DIR" != "/" ]; do
  _LIB_DIR="$(dirname "$_LIB_DIR")"
done
# shellcheck source=/dev/null
. "$_LIB_DIR/lib/log.sh"

if [ -z "$SERVICES_DATA_DIR" ]; then
  log_error "SERVICES_DATA_DIR is not set"
  exit 1
fi

_shared_dir="$SERVICES_DATA_DIR/_shared"
_target="$_shared_dir/caddy-root-ca.crt"

mkdir -p "$_shared_dir"

# Wait for Caddy to generate the root CA (up to 30 seconds)
_tries=0
while [ "$_tries" -lt 30 ]; do
  if docker exec caddy test -f /data/caddy/pki/authorities/local/root.crt 2>/dev/null; then
    break
  fi
  _tries=$((_tries + 1))
  sleep 1
done

if [ "$_tries" -ge 30 ]; then
  log_error "Caddy did not generate root CA"
  exit 1
fi

docker cp caddy:/data/caddy/pki/authorities/local/root.crt "$_target"
log_item "Exported Caddy root CA to $_target"
