#!/bin/sh
set -e

# Show listening TCP ports in a formatted table.
# Requires: sudo (for lsof)

_LIB_DIR="$(
  cd "$(dirname "$0")" || exit
  pwd
)"
while [ ! -f "$_LIB_DIR/lib/log.sh" ] && [ "$_LIB_DIR" != "/" ]; do
  _LIB_DIR="$(dirname "$_LIB_DIR")"
done
# shellcheck source=/dev/null
. "$_LIB_DIR/lib/log.sh"

log_header "Listening TCP ports"

RAW=$(sudo lsof -iTCP -sTCP:LISTEN -nP 2>/dev/null) || {
  log_error "Failed to query listening ports (sudo required)"
  exit 1
}

# Parse unique port/process/user/protocol combinations
printf '%s\n' "$RAW" | awk 'NR > 1 {
  cmd  = $1
  user = $3
  name = $9

  # Extract port from the NAME field (e.g. *:22 or [::]:22)
  split(name, a, ":")
  port = a[length(a)]

  # Detect protocol from the TYPE field
  proto = ($5 ~ /6/) ? "IPv6" : "IPv4"

  key = port SUBSEP cmd SUBSEP user
  if (!(key in seen)) {
    seen[key] = 1
    protos[key] = proto
    ports[++n] = port
    cmds[n]    = cmd
    users[n]   = user
  } else {
    if (index(protos[key], proto) == 0)
      protos[key] = protos[key] " + " proto
  }
}
END {
  fmt = "   %-8s %-18s %-12s %s\n"
  printf "\n"
  printf fmt, "PORT", "PROCESS", "USER", "PROTOCOL"
  printf fmt, "--------", "------------------", "------------", "------------"
  for (i = 1; i <= n; i++) {
    k = ports[i] SUBSEP cmds[i] SUBSEP users[i]
    printf fmt, ports[i], cmds[i], users[i], protos[k]
  }
  printf "\n"
}'
