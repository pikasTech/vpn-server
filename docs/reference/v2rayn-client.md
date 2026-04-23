# Client Configuration

## Current Mainline

The default recommended client protocol is `Hysteria2`.

### Entry Points

```text
Subscription: http://74.48.78.17:8080/subscribe
YAML: http://74.48.78.17:8080/hysteria2-client.yaml
Share link: http://74.48.78.17:8080/hysteria2-link
```

### Mainline Parameters

| Item | Value |
|------|-------|
| Protocol | `Hysteria2` |
| Host | `74-48-78-17.nip.io` |
| Port | `8444/udp` |
| TLS SNI | `74-48-78-17.nip.io` |
| Recommended client bandwidth | `up: 40 mbps / down: 80 mbps` |
| Example local socks5 | `127.0.0.1:10888` |

## Stable Client Rule

For the current path, the best stable result comes from moderate client-side bandwidth declarations. The recommended setting is `up: 40 mbps / down: 80 mbps`.

Do not blindly raise the client bandwidth to values such as `150 mbps`, `500 mbps`, or `1000 mbps`. Over-declaring the client bandwidth makes the current path slower and less stable.

## Why This Is Mainline

Under the fixed server region and current path conditions:

- TCP mainline is only about `0.1 MB/s`
- Hysteria2 reaches about `8-9 MB/s` on a single stream after tuning
- Parallel downloads are typically around `9-11 MB/s`

For this reason, Hysteria2 is the default recommendation.

## v2rayN Note

For `v2rayN`, keep the Hysteria global setting aligned with the published client value:

- `UpMbps = 40`
- `DownMbps = 80`
- `HopInterval = 30`

If the imported node is correct but throughput is unexpectedly poor, first check whether the local v2rayN Hysteria global values drifted away from the recommended range.

## Subscription Sync Requirement

`/subscribe` must always point to the current mainline. While Hysteria2 is mainline, decoding `/subscribe` must yield `hysteria2://...#US-Hysteria2-Main`. If a client refresh still shows `VLESS + tcp`, first check whether `/root/vpn-server/xray/html/subscribe` still contains an old link, then check whether the local v2rayN database still keeps the stale subscription node.

## Fallback

If the fallback `VLESS + REALITY` line is needed:

- Share link: `http://74.48.78.17:8080/reality-link`

`/subscribe` is reserved for the current mainline and is no longer the REALITY fallback entry.

## Acceptance Criteria

A client setup is considered correct when all of the following are true:

- The imported node is Hysteria2.
- The local socks5 port is listening.
- Access to `https://api.ipify.org` through the local proxy returns `74.48.78.17`.
- Large-file download speed is materially better than the TCP fallback.
- The client bandwidth is still near the recommended `40/80` range.
