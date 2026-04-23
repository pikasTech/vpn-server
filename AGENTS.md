# VPN 服务器

## 入口文档

- [架构与操作](docs/reference/server-overview.md)
- [服务器部署与变更流程](docs/reference/server-deploy.md)
- [主线路客户端配置](docs/reference/v2rayn-client.md)
- [性能故障排除与测量](docs/reference/performance-troubleshooting.md)
- [过程记录：初始部署](docs/process/2026-04-23-vpn-setup.md)
- [过程记录：连接调试](docs/process/debug-connection.md)
- [过程记录：REALITY 修复](docs/process/2026-04-23-reality-fix.md)

## 当前主线路

| 项目 | 值 |
|------|-------|
| 主协议 | Hysteria2 |
| 主服务端口 | `8444/udp` |
| 主容器 | `hysteria2` |
| 主订阅 | `http://74.48.78.17:8080/subscribe` |
| 主分享链接 | `http://74.48.78.17:8080/hysteria2-link` |
| 主 YAML 配置 | `http://74.48.78.17:8080/hysteria2-client.yaml` |
| 主线路服务器规则 | `不设置服务器带宽` |
| 建议客户端带宽 | `上传: 40 mbps / 下载: 80 mbps` |
| 当前吞吐量基准 | `单流约 8-9 MB/s; 并行下载约 9-11 MB/s` |

## 备用线路

| 项目 | 值 |
|------|-------|
| 备用协议 | VLESS + REALITY |
| 备用端口 | `8443/tcp` |
| 备用容器 | `xray8443` |
| 备用分享链接 | `http://74.48.78.17:8080/reality-link` |

## 命令索引

- `docker ps --format 'table {{.Names}}	{{.Status}}	{{.Ports}}'`: 检查运行中的容器。
- `docker logs hysteria2 --tail 100`: 检查主线路 Hysteria2 服务。
- `sed -n '1,80p' /root/vpn-server/hysteria2/config.yaml`: 检查当前服务器配置。
- `curl http://74.48.78.17:8080/hysteria2-client.yaml`: 获取主线路 YAML 客户端配置。
- `curl http://74.48.78.17:8080/hysteria2-link`: 获取主线路 Hysteria2 分享链接。
- `curl http://74.48.78.17:8080/subscribe | base64 -d`: 验证订阅端点与当前主线路一致。
- `curl http://74.48.78.17:8080/reality-link`: 获取 REALITY 备用分享链接。
- `ss -tulpn | grep -E ':8444|:8443|:8080'`: 验证监听端口。

## 目录索引

- `hysteria2/`: 当前主线路配置。
- `reality/`: REALITY 备用配置。
- `xray/`: nginx 分发层和发布的客户端文件。
- `docs/reference/`: 长期稳定的文档。
- `docs/process/`: 历史过程记录，仅追加。
- `trojan/`, `trojan-final/`, `trojan-new/`, `config/`: 遗留历史，非默认部署路径。