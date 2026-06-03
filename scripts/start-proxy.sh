#!/bin/sh
# start-proxy.sh - launched via POST_CONNECT once the NordVPN tunnel is up.
#
# Invoked as: sh /scripts/start-proxy.sh  (POST_CONNECT in docker-compose.yml)
# so it does not depend on the file's executable bit surviving the Windows
# bind mount.
#
# Idempotent: if the VPN drops and reconnects, POST_CONNECT fires again, so we
# kill any existing tinyproxy before starting a fresh one in the foreground.

set -e

PORT="${PROXY_PORT:-39888}"
# tinyproxy.conf is on a read-only-friendly bind mount, so render a runtime
# copy in /tmp with the chosen port substituted in.
CONF=/tmp/tinyproxy.conf
sed "s/^Port .*/Port ${PORT}/" /scripts/tinyproxy.conf > "$CONF"

# Stop a previous instance (no-op on first run).
pkill -x tinyproxy 2>/dev/null || true
# Give it a moment to release the port.
i=0
while pgrep -x tinyproxy >/dev/null 2>&1 && [ "$i" -lt 10 ]; do
  i=$((i + 1))
  sleep 0.2
done

# Start tinyproxy daemonized (per `Daemon Yes` in the conf). It forks into the
# background and this script exits, so POST_CONNECT returns cleanly.
echo "[start-proxy] launching tinyproxy on :${PORT} (egress via VPN)"
tinyproxy -c "$CONF"
echo "[start-proxy] tinyproxy started"
