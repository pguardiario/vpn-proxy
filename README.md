# vpn-proxy (nord-box)

A Docker container that connects to NordVPN and exposes a **local HTTP/HTTPS
proxy** on `127.0.0.1:39888`. Point a tool or browser at it and its traffic
egresses through the VPN tunnel - useful for bypassing datacenter-IP blocks.

The proxy ([tinyproxy](https://tinyproxy.github.io/)) is started automatically
via the image's `POST_CONNECT` hook once the tunnel is up.

## Setup

```bash
cp .env.example .env
# edit .env and set TOKEN= to your NordVPN token
docker compose up -d --build
```

## Use it

```bash
# HTTP and HTTPS both go through the same proxy
curl -x http://127.0.0.1:39888 https://api.ipify.org   # should show the VPN exit IP
```

Browser / app proxy setting: `HTTP proxy = 127.0.0.1`, `Port = 39888` (also
use it for HTTPS). Change the port by setting `PROXY_PORT` in `.env`.

## Notes

- The proxy is published on `127.0.0.1` only, so it is reachable from the host
  machine, not the LAN.
- `TOKEN` and other settings live in `.env` (gitignored). See `.env.example`.
- On VPN reconnect, `POST_CONNECT` re-fires and `scripts/start-proxy.sh`
  restarts tinyproxy cleanly.

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Service definition, ports, env wiring |
| `Dockerfile` | Base nordvpn image + tinyproxy and tools |
| `scripts/start-proxy.sh` | POST_CONNECT hook - (re)starts the proxy |
| `scripts/tinyproxy.conf` | Proxy config template (port set from `PROXY_PORT`) |
| `.env.example` | Template for `.env` |
