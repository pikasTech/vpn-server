# VPN Server

## Entry Points

- [Architecture and operations](docs/reference/server-overview.md)
- [Server deployment and change workflow](docs/reference/server-deploy.md)
- [Mainline client configuration](docs/reference/v2rayn-client.md)
- [Performance troubleshooting and measurement](docs/reference/performance-troubleshooting.md)
- [Process note: initial deployment](docs/process/2026-04-23-vpn-setup.md)
- [Process note: connection debugging](docs/process/debug-connection.md)
- [Process note: REALITY fix](docs/process/2026-04-23-reality-fix.md)

## Current Mainline

| Item | Value |
|------|-------|
| Main protocol | Hysteria2 |
| Main service port | `8444/udp` |
| Main container | `hysteria2` |
| Main subscription | `http://74.48.78.17:8080/subscribe` |
| Main share link | `http://74.48.78.17:8080/hysteria2-link` |
| Main YAML config | `http://74.48.78.17:8080/hysteria2-client.yaml` |
| Mainline server rule | `do not set server bandwidth` |
| Recommended client bandwidth | `up: 40 mbps / down: 80 mbps` |
| Current throughput baseline | `single stream about 8-9 MB/s; parallel downloads around 9-11 MB/s` |

## Fallback

| Item | Value |
|------|-------|
| Fallback protocol | VLESS + REALITY |
| Fallback port | `8443/tcp` |
| Fallback container | `xray8443` |
| Fallback share link | `http://74.48.78.17:8080/reality-link` |

## Command Index

- `docker ps --format 'table {{.Names}}	{{.Status}}	{{.Ports}}'`: inspect running containers.
- `docker logs hysteria2 --tail 100`: inspect the mainline Hysteria2 service.
- `sed -n '1,80p' /root/vpn-server/hysteria2/config.yaml`: inspect the live server config.
- `curl http://74.48.78.17:8080/hysteria2-client.yaml`: fetch the mainline YAML client config.
- `curl http://74.48.78.17:8080/hysteria2-link`: fetch the mainline Hysteria2 share link.
- `curl http://74.48.78.17:8080/subscribe | base64 -d`: verify that the subscription endpoint matches the current mainline.
- `curl http://74.48.78.17:8080/reality-link`: fetch the REALITY fallback share link.
- `ss -tulpn | grep -E ':8444|:8443|:8080'`: verify listening ports.

## Directory Index

- `hysteria2/`: current mainline configuration.
- `reality/`: REALITY fallback configuration.
- `xray/`: nginx distribution layer and published client files.
- `docs/reference/`: long-term stable documentation.
- `docs/process/`: historical process records. Append only.
- `trojan/`, `trojan-final/`, `trojan-new/`, `config/`: legacy history, not the default deployment path.
