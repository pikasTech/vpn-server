# Server Overview

## Goal

This project maintains a self-hosted proxy service for Windows clients. The current mainline is `Hysteria2` because it performs materially better than the TCP-based line under the fixed server region and current network path. `VLESS + REALITY` remains as a fallback only.

## Current Online Architecture

### Mainline

- Protocol: `Hysteria2`
- Port: `8444/udp`
- Config directory: `/root/vpn-server/hysteria2/`
- Running container: `hysteria2`
- Client subscription: `http://74.48.78.17:8080/subscribe`
- Client share link: `http://74.48.78.17:8080/hysteria2-link`
- Client YAML: `http://74.48.78.17:8080/hysteria2-client.yaml`

### Fallback

- Protocol: `VLESS + REALITY`
- Port: `8443/tcp`
- Config directory: `/root/vpn-server/reality/config/`
- Running container: `xray8443`
- Fallback share link: `http://74.48.78.17:8080/reality-link`

### Distribution Layer

- nginx config: `/root/vpn-server/xray/nginx.conf`
- Running container: `xray-nginx`
- Published file directory: `/root/vpn-server/xray/html/`

## Why Hysteria2 Is Mainline

- The VPS itself has healthy outbound bandwidth.
- The TCP line is limited to roughly `0.1 MB/s` on the current path.
- Under the same environment, Hysteria2 reaches about `8-9 MB/s` on a single stream and roughly `9-11 MB/s` with parallel downloads after tuning.
- The server region is fixed, so the most effective optimization variable is protocol choice, not relocation.

## Mainline Operating Rule

The stable mainline policy is:

- Do not set `bandwidth` in `/root/vpn-server/hysteria2/config.yaml`.
- Publish client guidance through `/root/vpn-server/xray/html/hysteria2-client.yaml` with the recommended client value `up: 40 mbps / down: 80 mbps`.
- Keep `/subscribe` aligned with the current Hysteria2 share link.

This avoids reintroducing artificial server-side rate caps or unstable over-declared client bandwidth.

## Operational Boundaries

- `hysteria2` is the default recommended stack.
- `xray8443` stays available for compatibility and fallback.
- `xray-nginx` only publishes config files and test artifacts; it does not carry proxy traffic.
- `/subscribe` always means the current mainline subscription endpoint and must be updated whenever the mainline changes.
- `docs/reference/` stores stable long-term knowledge; dated records belong in `docs/process/`.

## Authoritative Values

| Item | Value |
|------|-------|
| Server IP | `74.48.78.17` |
| Mainline port | `8444/udp` |
| Fallback port | `8443/tcp` |
| Mainline subscription | `http://74.48.78.17:8080/subscribe` |
| Mainline share link | `http://74.48.78.17:8080/hysteria2-link` |
| Mainline YAML | `http://74.48.78.17:8080/hysteria2-client.yaml` |
| Server-side bandwidth rule | `unset` |
| Recommended client bandwidth | `up: 40 mbps / down: 80 mbps` |
| REALITY fallback share link | `http://74.48.78.17:8080/reality-link` |

## Constraints

- The server region is fixed and is not an optimization variable.
- Re-testing from a different local network did not materially change throughput.
- Further optimization should focus on protocol and client-side behavior first.
- Under the current path constraints, `30 MB/s` is not a realistic short-term target.

## Acceptance Criteria

The mainline is considered healthy when all of the following are true:

- `docker ps` shows both `hysteria2` and `xray-nginx` as `Up`.
- `ss -tulpn` shows `8444/udp` and `8080/tcp` listening.
- `curl http://74.48.78.17:8080/hysteria2-client.yaml` returns a valid client config.
- `curl http://74.48.78.17:8080/subscribe | base64 -d` returns the current Hysteria2 share link.
- The published YAML recommends `up: 40 mbps / down: 80 mbps`.
- A client using the Hysteria2 local socks5 port reaches `https://api.ipify.org` and sees `74.48.78.17`.
