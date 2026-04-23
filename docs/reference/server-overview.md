# 服务器概览

## 目标

本项目维护一个面向 Windows 客户端的自托管代理服务。当前端线为 `Hysteria2`，因为在固定服务器地域和当前网络路径下，其性能明显优于基于 TCP 的线路。`VLESS + REALITY` 仅作为备用保留。

## 当前在线架构

### 主线路

- 协议：`Hysteria2`
- 端口：`8444/udp`
- 配置目录：`/root/vpn-server/hysteria2/`
- 运行容器：`hysteria2`
- 客户端订阅：`http://74.48.78.17:8080/subscribe`
- 客户端分享链接：`http://74.48.78.17:8080/hysteria2-link`
- 客户端 YAML：`http://74.48.78.17:8080/hysteria2-client.yaml`

### 备用线路

- 协议：`VLESS + REALITY`
- 端口：`8443/tcp`
- 配置目录：`/root/vpn-server/reality/config/`
- 运行容器：`xray8443`
- 备用分享链接：`http://74.48.78.17:8080/reality-link`

### 分发层

- nginx 配置：`/root/vpn-server/xray/nginx.conf`
- 运行容器：`xray-nginx`
- 发布文件目录：`/root/vpn-server/xray/html/`

## 为什么 Hysteria2 是主线路

- VPS 本身有健康的上行带宽。
- 在当前路径上，TCP 线路被限制在大约 `0.1 MB/s`。
- 在相同环境下，Hysteria2 单流可达约 `8-9 MB/s`，调优后并行下载约 `9-11 MB/s`。
- 服务器地域是固定的，所以最有效的优化变量是协议选择，而非迁移。

## 主线路操作规则

稳定的端线策略：

- 不要在 `/root/vpn-server/hysteria2/config.yaml` 中设置 `bandwidth`。
- 通过 `/root/vpn-server/xray/html/hysteria2-client.yaml` 发布客户端指南，建议值为 `上传: 40 mbps / 下载: 80 mbps`。
- 保持 `/subscribe` 与当前 Hysteria2 分享链接同步。

这避免了重新引入人为的服务器端速率限制或不稳定地过度声明客户端带宽。

## 操作边界

- `hysteria2` 是默认推荐的堆栈。
- `xray8443` 保持可用以提供兼容性和备用。
- `xray-nginx` 仅发布配置文件和测试产物，不承载代理流量。
- `/subscribe` 始终指向当前主线路订阅端点，主线路变更时必须更新。
- `docs/reference/` 存储长期稳定的知识；带日期的记录应放在 `docs/process/`。

## 权威值

| 项目 | 值 |
|------|-------|
| 服务器 IP | `74.48.78.17` |
| 主线路端口 | `8444/udp` |
| 备用端口 | `8443/tcp` |
| 主线路订阅 | `http://74.48.78.17:8080/subscribe` |
| 主线路分享链接 | `http://74.48.78.17:8080/hysteria2-link` |
| 主线路 YAML | `http://74.48.78.17:8080/hysteria2-client.yaml` |
| 服务器端带宽规则 | `未设置` |
| 建议客户端带宽 | `上传: 40 mbps / 下载: 80 mbps` |
| REALITY 备用分享链接 | `http://74.48.78.17:8080/reality-link` |

## 约束条件

- 服务器地域是固定的，不是优化变量。
- 从不同本地网络重新测试没有显著改变吞吐量。
- 进一步优化应首先关注协议和客户端行为。
- 在当前路径约束下，`30 MB/s` 不是现实的短期目标。

## 验收标准

当以下全部为真时，端线被认为是健康的：

- `docker ps` 显示 `hysteria2` 和 `xray-nginx` 都是 `Up`。
- `ss -tulpn` 显示 `8444/udp` 和 `8080/tcp` 正在监听。
- `curl http://74.48.78.17:8080/hysteria2-client.yaml` 返回有效的客户端配置。
- `curl http://74.48.78.17:8080/subscribe | base64 -d` 返回当前的 Hysteria2 分享链接。
- 发布的 YAML 建议 `上传: 40 mbps / 下载: 80 mbps`。
- 使用 Hysteria2 本地 socks5 端口的客户端能到达 `https://api.ipify.org` 并看到 `74.48.78.17`。