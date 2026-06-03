#!/bin/sh
# switch-location.sh - hot-switch the VPN exit location WITHOUT restarting the
# container or the proxy. tinyproxy egresses through whatever the tunnel is, so
# the moment NordVPN reconnects, the proxy's exit IP changes too.
#
# Usage:
#   ./switch-location.sh <destination>   # e.g. Japan | United_States | Tokyo | us | P2P
#   ./switch-location.sh                  # no arg -> NordVPN's recommended server
#
# Discover valid destinations:
#   docker exec vpn-proxy nordvpn countries
#   docker exec vpn-proxy nordvpn cities <Country>
#   docker exec vpn-proxy nordvpn groups
#
# Note: this change is NOT persistent. On container recreate it reconnects to
# CONNECT from .env. To make a location stick, also update CONNECT in .env.

set -e

CONTAINER="${CONTAINER:-vpn-proxy}"
DEST="$1"

echo "[switch-location] reconnecting ${CONTAINER} -> ${DEST:-<recommended>}"
docker exec "$CONTAINER" nordvpn connect $DEST

echo
docker exec "$CONTAINER" nordvpn status
