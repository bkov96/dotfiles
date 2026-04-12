#!/bin/sh
set -e

# Service lifecycle manager.
# Usage: services.sh <action> [service_name]
# Actions: list, init, start, stop, restart, status

ACTION="$1"
SERVICE_NAME="$2"
PROFILE_DIR="$3"

REPO_DIR="$(
  cd "$(dirname "$0")" || exit
  pwd
)"
while [ ! -f "$REPO_DIR/lib/log.sh" ] && [ "$REPO_DIR" != "/" ]; do
  REPO_DIR="$(dirname "$REPO_DIR")"
done
SERVICES_DIR="$(cd "$(dirname "$0")/../services" && pwd)"
CADDY_ROUTES_DIR="$SERVICES_DIR/caddy/routes"

# shellcheck source=/dev/null
. "$REPO_DIR/lib/log.sh"
# shellcheck source=/dev/null
. "$REPO_DIR/lib/resolve.sh"

INFRA_SERVICES="adguard_home caddy"

# --- Helpers ---

# List all service directory names (any dir containing docker-compose.yml.tmpl)
all_services() {
  for dir in "$SERVICES_DIR"/*/; do
    [ -f "$dir/docker-compose.yml.tmpl" ] && basename "$dir"
  done
}

# Return services in start order: infra first, then the rest alphabetically
ordered_services() {
  _rest=""
  for svc in $(all_services); do
    _is_infra=0
    for infra in $INFRA_SERVICES; do
      [ "$svc" = "$infra" ] && _is_infra=1 && break
    done
    if [ "$_is_infra" -eq 0 ]; then
      _rest="$_rest $svc"
    fi
  done
  printf '%s' "$INFRA_SERVICES$(printf '%s' "$_rest" | tr ' ' '\n' | sort | tr '\n' ' ')"
}

# Return services in stop order (reverse of start order)
reverse_ordered_services() {
  ordered_services | tr ' ' '\n' | awk '{lines[NR]=$0} END{for(i=NR;i>=1;i--) print lines[i]}' | tr '\n' ' '
}

# Check if a service directory exists
validate_service() {
  if [ ! -f "$SERVICES_DIR/$1/docker-compose.yml.tmpl" ]; then
    log_error "Unknown service: $1"
    log_info "Available services: $(all_services | tr '\n' ' ')"
    exit 1
  fi
}

# Resolve env vars from .config.json + Bitwarden, export them and set ENVSUBST_VARS
load_env() {
  BW_ITEM="dotfiles/$DOTFILES_PROFILE/$DOTFILES_PLATFORM"

  if has_bw_refs "$PROFILE_DIR/.config.json"; then
    ensure_bw_session
    fetch_bw_item "$BW_ITEM"
  fi

  for key in $(jq -r '.env // {} | keys[]' "$PROFILE_DIR/.config.json"); do
    raw=$(jq -r --arg k "$key" '.env[$k]' "$PROFILE_DIR/.config.json")
    value=$(resolve_value "$raw")
    export "$key=$value"
  done

  ENVSUBST_VARS=$(jq -r '.env // {} | keys[] | "$" + .' "$PROFILE_DIR/.config.json" | tr '\n' ' ')
}

# Render all .tmpl files in a service directory (excluding caddy.snippet.tmpl)
render_templates() {
  _svc_dir="$SERVICES_DIR/$1"
  for tmpl in "$_svc_dir"/*.tmpl; do
    [ -f "$tmpl" ] || continue
    _basename=$(basename "$tmpl")
    # Skip caddy snippets — handled separately
    [ "$_basename" = "caddy.snippet.tmpl" ] && continue
    _target="$_svc_dir/$(echo "$_basename" | sed 's/\.tmpl$//')"
    envsubst "$ENVSUBST_VARS" <"$tmpl" >"$_target"
    log_item "Rendered $_basename"
  done
}

# Copy rendered config files into the service's data directory
# Some services (e.g., AdGuard Home) need to write to their config at runtime,
# so we copy rather than bind-mount read-only.
install_config_to_data() {
  _svc="$1"
  _svc_dir="$SERVICES_DIR/$_svc"
  _data="$SERVICES_DATA_DIR/$_svc"
  case "$_svc" in
  adguard_home)
    if [ -f "$_svc_dir/AdGuardHome.yaml" ]; then
      mkdir -p "$_data/conf"
      cp "$_svc_dir/AdGuardHome.yaml" "$_data/conf/AdGuardHome.yaml"
      log_item "Installed AdGuard Home config to data directory"
    fi
    ;;
  esac
}

# Copy the service's caddy.snippet.tmpl (rendered) into caddy/routes/
install_caddy_route() {
  _svc="$1"
  _snippet="$SERVICES_DIR/$_svc/caddy.snippet.tmpl"
  [ -f "$_snippet" ] || return 0
  mkdir -p "$CADDY_ROUTES_DIR"
  envsubst "$ENVSUBST_VARS" <"$_snippet" >"$CADDY_ROUTES_DIR/$_svc.snippet"
  log_item "Installed Caddy route for $_svc"
}

# Remove the service's caddy route snippet
remove_caddy_route() {
  _svc="$1"
  _route="$CADDY_ROUTES_DIR/$_svc.snippet"
  [ -f "$_route" ] || return 0
  rm -f "$_route"
  log_item "Removed Caddy route for $_svc"
}

# Reload Caddy if it's running
reload_caddy() {
  if docker compose -f "$SERVICES_DIR/caddy/docker-compose.yml" ps --status running 2>/dev/null | grep -q caddy; then
    docker compose -f "$SERVICES_DIR/caddy/docker-compose.yml" exec caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || true
    log_item "Reloaded Caddy"
  fi
}

# Check if a service is running (any container up)
is_running() {
  _svc_dir="$SERVICES_DIR/$1"
  [ -f "$_svc_dir/docker-compose.yml" ] || return 1
  docker compose -f "$_svc_dir/docker-compose.yml" ps --status running 2>/dev/null | grep -q . 2>/dev/null
}

# Create data directory for a service
create_data_dir() {
  if [ -z "$SERVICES_DATA_DIR" ]; then
    log_error "SERVICES_DATA_DIR is not set. Check your .config.json."
    exit 1
  fi
  _data="$SERVICES_DATA_DIR/$1"
  if [ ! -d "$_data" ]; then
    mkdir -p "$_data"
    log_item "Created data directory: $_data"
  fi
}

# Ensure shared Docker networks exist
ensure_networks() {
  if ! docker network inspect caddy_proxy >/dev/null 2>&1; then
    docker network create caddy_proxy >/dev/null
    log_item "Created caddy_proxy network"
  fi
}

# --- Actions ---

do_init() {
  _svc="$1"
  log_header "Initializing $_svc..."
  validate_service "$_svc"
  load_env
  create_data_dir "$_svc"
  render_templates "$_svc"
  install_config_to_data "$_svc"
  if [ -f "$SERVICES_DIR/$_svc/init.sh" ]; then
    sh "$SERVICES_DIR/$_svc/init.sh" "$SERVICES_DIR/$_svc"
  fi
  log_ok "$_svc initialized"
}

do_start() {
  _svc="$1"
  log_header "Starting $_svc..."
  validate_service "$_svc"
  load_env
  ensure_networks
  create_data_dir "$_svc"
  render_templates "$_svc"
  install_config_to_data "$_svc"
  install_caddy_route "$_svc"
  if [ "$_svc" != "caddy" ]; then
    reload_caddy
  fi
  docker compose -f "$SERVICES_DIR/$_svc/docker-compose.yml" up -d
  if [ -f "$SERVICES_DIR/$_svc/post-start.sh" ]; then
    sh "$SERVICES_DIR/$_svc/post-start.sh" "$SERVICES_DIR/$_svc"
  fi
  log_ok "$_svc started"
}

do_stop() {
  _svc="$1"
  log_header "Stopping $_svc..."
  validate_service "$_svc"
  if [ -f "$SERVICES_DIR/$_svc/docker-compose.yml" ]; then
    docker compose -f "$SERVICES_DIR/$_svc/docker-compose.yml" down
    remove_caddy_route "$_svc"
    if [ "$_svc" != "caddy" ]; then
      reload_caddy
    fi
    log_ok "$_svc stopped"
  else
    log_info "$_svc not initialized, nothing to stop"
  fi
}

do_restart() {
  do_stop "$1"
  do_start "$1"
}

do_status() {
  _svc="$1"
  validate_service "$_svc"
  log_header "Status: $_svc"
  if [ -f "$SERVICES_DIR/$_svc/docker-compose.yml" ]; then
    docker compose -f "$SERVICES_DIR/$_svc/docker-compose.yml" ps
  else
    log_info "Not initialized (no rendered docker-compose.yml)"
  fi
}

do_list() {
  log_header "Services"
  for svc in $(ordered_services); do
    if is_running "$svc"; then
      log_ok "$svc"
    else
      log_info "$svc (stopped)"
    fi
  done
}

# --- Main ---

case "$ACTION" in
list)
  do_list
  ;;
init | start | stop | restart | status)
  if [ -n "$SERVICE_NAME" ]; then
    "do_$ACTION" "$SERVICE_NAME"
  else
    if [ "$ACTION" = "status" ]; then
      for svc in $(ordered_services); do
        do_status "$svc"
      done
    elif [ "$ACTION" = "stop" ]; then
      for svc in $(reverse_ordered_services); do
        "do_$ACTION" "$svc"
      done
    else
      for svc in $(ordered_services); do
        "do_$ACTION" "$svc"
      done
    fi
  fi
  ;;
*)
  log_error "Unknown action: $ACTION"
  printf '\n  Usage: services.sh <action> [service_name]\n'
  printf '  Actions: list, init, start, stop, restart, status\n\n'
  exit 1
  ;;
esac
