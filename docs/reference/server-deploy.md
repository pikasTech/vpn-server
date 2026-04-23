# Server Deployment

## Scope

This document covers the current default deployment path: `Hysteria2 + Docker`. `VLESS + REALITY` is kept only as a fallback.

## Preconditions

- Ubuntu 22.04 x86_64
- Docker installed
- Public IP reachable
- Working directory: `/root/vpn-server/`

## Mainline File Layout

- `hysteria2/hysteria`: server binary
- `hysteria2/config.yaml`: live server configuration
- `xray/html/hysteria2-client.yaml`: Hysteria2 YAML client config
- `xray/html/hysteria2-link`: Hysteria2 plain share link
- `xray/html/subscribe`: base64-encoded mainline share link
- `xray/nginx.conf`: nginx distribution config

## Mainline Deployment Steps

1. Prepare `hysteria2/config.yaml`.
2. Prepare `xray/html/hysteria2-client.yaml`.
3. Prepare `xray/html/hysteria2-link` and `xray/html/subscribe`. `/subscribe` must be the base64-encoded form of the current mainline share link.
4. Start Hysteria2:

```bash
docker run -d --name hysteria2 --restart unless-stopped   -p 8444:8444/udp   -v /root/vpn-server/hysteria2:/etc/hysteria   tobyxdd/hysteria server -c /etc/hysteria/config.yaml
```

5. Verify that nginx publishes both the config files and the subscription endpoint:

```bash
curl http://74.48.78.17:8080/hysteria2-client.yaml
curl http://74.48.78.17:8080/hysteria2-link
curl http://74.48.78.17:8080/subscribe | base64 -d
```

## Mainline Switch Sync Rule

When the mainline protocol, port, hostname, password, or share parameters change, update all of the following together so that clients do not keep importing an old protocol:

- `/root/vpn-server/hysteria2/config.yaml`: live server config.
- `/root/vpn-server/xray/html/hysteria2-client.yaml`: YAML client config.
- `/root/vpn-server/xray/html/hysteria2-link`: plain share link.
- `/root/vpn-server/xray/html/subscribe`: base64-encoded current mainline share link.

The acceptance rule is that decoding `/subscribe` must produce the current mainline share link; it is not enough to only confirm that the server container was changed.

## Baseline System Tuning

Keep the following baseline checks available:

```bash
sysctl net.ipv4.tcp_congestion_control
sysctl net.core.default_qdisc
sysctl net.core.rmem_max net.core.wmem_max
sysctl net.core.rmem_default net.core.wmem_default
```

## Fallback Note

If Hysteria2 must be rolled back temporarily, keep using `xray8443` for `VLESS + REALITY`, but do not treat it as the default line.

## Acceptance

```bash
docker ps --format 'table {{.Names}}	{{.Status}}	{{.Ports}}'
ss -tulpn | grep -E ':8444|:8080'
curl http://74.48.78.17:8080/hysteria2-client.yaml
curl http://74.48.78.17:8080/subscribe | base64 -d
```
