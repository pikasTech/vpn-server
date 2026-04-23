# Performance Troubleshooting

## Goal

This document records stable troubleshooting methods, tuning conclusions, and current baselines for separating VPS bandwidth issues, client-to-server path issues, and protocol-stack issues.

## Measurement Model

Always separate these three segments:

1. VPS outbound speed to the public Internet
2. Client direct speed to the server distribution port
3. Client speed through the proxy stack

If one segment is much slower than the others, do not treat the result as a generic server-bandwidth problem.

## Reusable Test Methods

### 1. VPS Self-Test

Use this to confirm that the VPS itself still has healthy public bandwidth.

```bash
curl -L -o /dev/null -w 'status=%{http_code} time=%{time_total}s speed=%{speed_download}B/s
'   https://cachefly.cachefly.net/50mb.test --max-time 90
```

### 2. Client Direct-to-Server Test

Use this to measure the raw client-to-server path.

```powershell
curl.exe --noproxy '*' -L -o NUL -w "status=%{http_code} time=%{time_total}s speed=%{speed_download}B/s`n"   http://74.48.78.17:8080/speed-100m.bin --max-time 90
```

### 3. Client Through-Proxy Test

Use this to measure the practical proxy result.

```powershell
curl.exe --socks5-hostname 127.0.0.1:7890 -L -o NUL -w "status=%{http_code} time=%{time_total}s speed=%{speed_download}B/s`n"   https://cachefly.cachefly.net/50mb.test --max-time 90
```

## Stable Baseline Conclusions

The current reusable conclusions are:

- The VPS itself downloads from the public Internet at about `83-99 MB/s`, so the server is not the bottleneck.
- Client direct download from the server distribution port is only about `0.14-0.15 MB/s` on the problematic TCP path.
- TCP-based proxy tests stay in the same very low range, so the weak segment is the client-to-server path, not VPS bandwidth.
- On the same fixed region and path, switching from TCP-based mainline to UDP-based Hysteria2 is the only change that produces an order-of-magnitude improvement.

## Mainline Tuning Outcome

The current best stable Hysteria2 policy is:

- Server side: do not set `bandwidth` in `/root/vpn-server/hysteria2/config.yaml`
- Published client YAML: `up: 40 mbps / down: 80 mbps`
- v2rayN Hysteria global values: `UpMbps = 40`, `DownMbps = 80`, `HopInterval = 30`

With this policy, the current path typically reaches:

- Single-stream Hysteria2 download: about `8-9 MB/s`
- Parallel Hysteria2 downloads: about `9-11 MB/s`

## Tuning Findings That Matter

The following distilled findings should guide future tuning:

- A server-side `bandwidth.up: 100 mbps` cap creates a practical ceiling near `12.5 MB/s`, which limits aggregate download throughput.
- Removing the server-side `bandwidth` section is better than keeping an underestimated hard cap.
- The current path does not benefit from aggressively over-declared client bandwidth.
- Client values around `down: 80 mbps` are the current sweet spot.
- Raising the client declaration too far, such as `150 mbps` or `1000 mbps`, makes throughput worse instead of better.
- A temporary UDP `443` test instance did not materially outperform the normal `8444/udp` mainline, so there is no stable evidence that moving the mainline port to `443/udp` is worthwhile.

## Parameter Sweep Summary

The following parameter sweep produced the stable recommendation:

- `up: 40 mbps / down: 80 mbps`: about `9.2 MB/s`, best stable result
- `up: 80 mbps / down: 80 mbps`: about `9.2 MB/s`, similar but not better
- `up: 60 mbps / down: 90 mbps`: about `9.19 MB/s`, similar but not better
- `up: 80 mbps / down: 90 mbps`: about `9.06 MB/s`, slightly worse
- `up: 150 mbps / down: 150 mbps`: materially worse
- `up: 1000 mbps / down: 1000 mbps`: much worse
- no client `bandwidth` section: worse than the tuned range

For future maintenance, treat `40/80` as the default recommendation unless repeated testing on a new path proves otherwise.

## Excluded Variables

The following factors have already been checked and should not be rediscovered as main explanations without new evidence:

- Re-testing from another local network did not materially change throughput.
- The server region is fixed and is not part of the current optimization space.
- Basic Linux queue and TCP settings already keep the server in a reasonable baseline state:
  - `net.ipv4.tcp_congestion_control = bbr`
  - `net.core.default_qdisc = fq`
  - `net.core.rmem_max = 67108864`
  - `net.core.wmem_max = 67108864`
  - `net.core.rmem_default = 1048576`
  - `net.core.wmem_default = 1048576`

## Practical Decision Rules

Use these rules when speed is poor:

- If the VPS self-test is fast but direct client-to-server download is slow, suspect the access network, ISP path, or cross-border path first.
- If direct client-to-server download is normal but proxy download is much slower, check the client implementation and client-side proxy settings.
- If UDP-based Hysteria2 is much faster than TCP-based tests, prefer changing protocol rather than micro-tuning Linux TCP knobs.
- If a higher declared Hysteria2 bandwidth makes the path slower, move back toward the last proven range instead of assuming that larger values are always better.
- If single-stream speed is stuck near `8-9 MB/s` on this path, do not promise `30 MB/s` without changing a larger variable such as region, upstream path, or network environment.

## Recommended Next-Step Logic

When the target is much higher than the current baseline, the meaningful next variables are:

- a different local access network or ISP path
- a different server region
- an intermediate relay or premium transit path
- workload-level parallelism instead of chasing single-stream limits

Under the current constraints, protocol choice and moderate Hysteria2 client tuning are already the main effective levers.
