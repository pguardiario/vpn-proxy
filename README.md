# vpn-proxy

A small Docker container that connects to **NordVPN** and exposes a **local
HTTP/HTTPS proxy**. Point any tool or browser at the proxy and its traffic
egresses through the VPN tunnel - handy for getting off a datacenter IP that's
being blocked, geo-testing, or routing a single app through the VPN without
touching the rest of the host.

Under the hood it's the [`bubuntux/nordvpn`](https://github.com/bubuntux/nordvpn)
image plus [tinyproxy](https://tinyproxy.github.io/). The proxy is started
automatically by the image's `POST_CONNECT` hook once the tunnel is up.

```
your app ──▶ 127.0.0.1:39888 (tinyproxy, in container) ──▶ NordVPN tunnel ──▶ internet
```

## Requirements

- Docker + Docker Compose v2 (`docker compose ...`)
- A NordVPN account and an **access token**
  (Nord account → *Services → NordVPN → Manual setup → access token*)
- `NET_ADMIN` capability (granted in the compose file) - so it needs to run on
  a host where you can use that, i.e. not most shared/PaaS environments.

## Setup

```bash
git clone https://github.com/pguardiario/vpn-proxy.git
cd vpn-proxy

cp .env.example .env
# edit .env and set TOKEN= to your NordVPN access token
nano .env

docker compose up -d --build
```

Watch it connect and start the proxy:

```bash
docker compose logs -f
```

You're looking for:

```
You are connected to United States #..... !
[start-proxy] launching tinyproxy on :39888 (egress via VPN)
[start-proxy] tinyproxy started
```

## Verify it's routing through the VPN

```bash
# the host's real IP
curl -s https://api.ipify.org; echo

# through the proxy - should be a DIFFERENT IP (the NordVPN exit)
curl -s -x http://127.0.0.1:39888 https://api.ipify.org; echo
```

If the second IP differs from the first, you're proxied through the VPN.

## Using the proxy

Locally (same machine as the container):

```bash
curl -x http://127.0.0.1:39888 https://example.com
```

Browser / app proxy setting: HTTP proxy `127.0.0.1`, port `39888` (use the same
for HTTPS).

**From another machine** (e.g. the container runs on a VPS): the proxy is bound
to `127.0.0.1` on purpose (see Security). Don't expose it publicly - tunnel it
over SSH instead:

```bash
ssh -N -L 39888:127.0.0.1:39888 user@your-server
# now http://127.0.0.1:39888 on your laptop reaches the proxy over SSH
```

## Changing the exit location

The exit IP is whichever NordVPN server you're connected to. You can switch it
two ways.

### Hot switch (no restart)

The proxy egresses through whatever the tunnel currently is, so reconnecting
NordVPN inside the running container changes the exit IP **instantly** - no
container restart, no dropped proxy. Use the helper:

```bash
./switch-location.sh Japan            # country
./switch-location.sh Tokyo            # city
./switch-location.sh United_States    # multi-word -> underscore
./switch-location.sh P2P              # server group
./switch-location.sh                  # NordVPN's recommended server
```

It just wraps:

```bash
docker exec vpn-proxy nordvpn connect <destination>
docker exec vpn-proxy nordvpn status
```

Discover valid destinations:

```bash
docker exec vpn-proxy nordvpn countries
docker exec vpn-proxy nordvpn cities <Country>
docker exec vpn-proxy nordvpn groups
```

Confirm the new exit IP:

```bash
curl -s -x http://127.0.0.1:39888 https://api.ipify.org; echo
```

> If the container runs on a remote host, prefix with SSH, e.g.
> `ssh user@server './vpn-proxy/switch-location.sh Japan'`.

### Persistent change

A hot switch does **not** survive a container recreate (it'll reconnect to
`CONNECT` from `.env`). To make a location the new default, edit `.env`:

```bash
CONNECT=Japan
```

then apply it:

```bash
docker compose up -d   # recreates the container with the new CONNECT
```

## Configuration

All config lives in `.env` (copied from `.env.example`):

| Variable     | Default              | Purpose                                              |
|--------------|----------------------|------------------------------------------------------|
| `TOKEN`      | *(required)*         | NordVPN access token                                 |
| `PROXY_PORT` | `39888`              | Proxy port (host + container). One source of truth.  |
| `TECHNOLOGY` | `NordLynx`           | NordVPN technology (`NordLynx` / `OpenVPN`)          |
| `CONNECT`    | `New_York`           | Server / country / city to connect to               |
| `NETWORK`    | `192.168.1.0/24`     | LAN allowed through the killswitch                  |

`PROXY_PORT` is the single source of truth: it sets the published port, the
killswitch allow-rule, and the port tinyproxy listens on (`start-proxy.sh`
renders the tinyproxy config from it at launch).

## Security

- The proxy is published on **`127.0.0.1` only**, so it is reachable from the
  host machine, not the LAN or the internet. This binding *is* the access
  control.
- tinyproxy runs with **no authentication** and allows all clients - which is
  fine *only* because of the loopback binding. **Do not change the publish to
  `0.0.0.0` without adding proxy auth**, or you create an open relay that
  scanners will find and abuse within minutes.
- Secrets live in `.env`, which is git-ignored. Never commit it. Use
  `.env.example` as the template.

## Troubleshooting

- **`Unable to parse config file`** - almost always Windows CRLF line endings in
  `scripts/`. This repo ships a `.gitattributes` that forces LF on checkout, so
  a clean `git clone` / `git pull` avoids it. If you edited files on Windows,
  re-checkout or run `sed -i 's/\r$//' scripts/*`.
- **Proxy curl hangs / connection refused** - check the container is healthy
  (`docker compose logs -f`) and that the VPN actually connected. The killswitch
  blocks all non-VPN traffic until the tunnel is up.

## Files

| File                      | Purpose                                             |
|---------------------------|-----------------------------------------------------|
| `docker-compose.yml`      | Service definition, ports, env wiring               |
| `Dockerfile`              | `bubuntux/nordvpn` base + tinyproxy and tools       |
| `switch-location.sh`      | Host helper - hot-switch the VPN exit location      |
| `scripts/start-proxy.sh`  | `POST_CONNECT` hook - (re)starts the proxy          |
| `scripts/tinyproxy.conf`  | Proxy config template (port injected from env)      |
| `.env.example`            | Template for `.env`                                 |
| `.gitattributes`          | Forces LF line endings (Linux deploy target)        |

## License

MIT - do whatever you like.
