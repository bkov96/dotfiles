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
CADDY_ROUTES_DIR="$SERVICES_DIR/network/caddy/routes"

# shellcheck source=/dev/null
. "$REPO_DIR/lib/log.sh"
# shellcheck source=/dev/null
. "$REPO_DIR/lib/resolve.sh"

INFRA_SERVICES="caddy"

# Services that bind-mount ${MEDIA_ROOT} and require the drive to be present
MEDIA_SERVICES="qbittorrent radarr sonarr lidarr bazarr jellyfin navidrome recyclarr seerr"

# --- Helpers ---

# List all service directory names (any dir containing docker-compose.yml.tmpl)
all_services() {
  for dir in "$SERVICES_DIR"/*/*/; do
    [ -f "$dir/docker-compose.yml.tmpl" ] && basename "$dir"
  done
}

# Resolve a service name to its full directory path
service_dir() {
  for dir in "$SERVICES_DIR"/*/*/; do
    [ -f "$dir/docker-compose.yml.tmpl" ] && [ "$(basename "$dir")" = "$1" ] && printf '%s' "${dir%/}" && return
  done
  return 1
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
  if [ -z "$(service_dir "$1")" ]; then
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

  # Derive MEDIA_VOLUME from MEDIA_ROOT (volume mount = parent of media library).
  # Used in Grafana provisioning to filter node_exporter mountpoint labels.
  if [ -n "$MEDIA_ROOT" ]; then
    MEDIA_VOLUME="${MEDIA_ROOT%/*}"
    export MEDIA_VOLUME
  fi

  ENVSUBST_VARS=$(jq -r '.env // {} | keys[] | "$" + .' "$PROFILE_DIR/.config.json" | tr '\n' ' ')
  ENVSUBST_VARS="$ENVSUBST_VARS \$MEDIA_VOLUME"
}

# Render all .tmpl files in a service directory and its subdirectories
# (excluding caddy.snippet.tmpl which is handled separately)
render_templates() {
  _svc_dir="$(service_dir "$1")"
  find "$_svc_dir" -name '*.tmpl' -type f | while IFS= read -r tmpl; do
    _basename=$(basename "$tmpl")
    # Skip caddy snippets — handled separately
    [ "$_basename" = "caddy.snippet.tmpl" ] && continue
    _target="${tmpl%.tmpl}"
    envsubst "$ENVSUBST_VARS" <"$tmpl" >"$_target"
    log_item "Rendered ${tmpl#"$_svc_dir/"}"
  done
}

# Copy rendered config files into the service's data directory.
# Some services need to write to their config at runtime,
# so we copy rather than bind-mount read-only.
install_config_to_data() {
  _svc="$1"
  # No services currently need this — kept as a hook for future use.
  :
}

# Copy the service's caddy.snippet.tmpl (rendered) into caddy/routes/
install_caddy_route() {
  _svc="$1"
  _snippet="$(service_dir "$_svc")/caddy.snippet.tmpl"
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
  _caddy_dir="$(service_dir "caddy")"
  if docker compose -f "$_caddy_dir/docker-compose.yml" ps --status running 2>/dev/null | grep -q caddy; then
    docker compose -f "$_caddy_dir/docker-compose.yml" exec caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || true
    log_item "Reloaded Caddy"
  fi
}

# Check if a service is running (any container up)
is_running() {
  _svc_dir="$(service_dir "$1")"
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
  if ! docker network inspect metrics_internal >/dev/null 2>&1; then
    docker network create metrics_internal >/dev/null
    log_item "Created metrics_internal network"
  fi
}

# Verify MEDIA_ROOT is mounted and looks like a real media library.
# Called before starting any service that bind-mounts ${MEDIA_ROOT}.
check_media_root() {
  _svc="$1"
  for media_svc in $MEDIA_SERVICES; do
    if [ "$_svc" = "$media_svc" ]; then
      if [ -z "$MEDIA_ROOT" ]; then
        log_error "MEDIA_ROOT is not set. Check .config.json."
        exit 1
      fi
      if [ ! -d "$MEDIA_ROOT/movies" ]; then
        log_error "MEDIA_ROOT=$MEDIA_ROOT does not contain movies/ — external drive not mounted? Refusing to start $_svc."
        exit 1
      fi
      return 0
    fi
  done
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
  _svc_dir="$(service_dir "$_svc")"
  if [ -f "$_svc_dir/init.sh" ]; then
    sh "$_svc_dir/init.sh" "$_svc_dir"
  fi
  log_ok "$_svc initialized"
}

do_start() {
  _svc="$1"
  log_header "Starting $_svc..."
  validate_service "$_svc"
  load_env
  check_media_root "$_svc"
  ensure_networks
  create_data_dir "$_svc"
  render_templates "$_svc"
  install_config_to_data "$_svc"
  install_caddy_route "$_svc"
  if [ "$_svc" != "caddy" ]; then
    reload_caddy
  fi
  _svc_dir="$(service_dir "$_svc")"
  docker compose -f "$_svc_dir/docker-compose.yml" up -d
  if [ -f "$_svc_dir/post-start.sh" ]; then
    sh "$_svc_dir/post-start.sh" "$_svc_dir"
  fi
  log_ok "$_svc started"
}

do_stop() {
  _svc="$1"
  log_header "Stopping $_svc..."
  validate_service "$_svc"
  _svc_dir="$(service_dir "$_svc")"
  if [ -f "$_svc_dir/docker-compose.yml" ]; then
    docker compose -f "$_svc_dir/docker-compose.yml" down
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
  _svc_dir="$(service_dir "$_svc")"
  if [ -f "$_svc_dir/docker-compose.yml" ]; then
    docker compose -f "$_svc_dir/docker-compose.yml" ps
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
