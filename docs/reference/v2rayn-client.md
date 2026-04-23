# 客户端配置

## 当前主线路

默认推荐的客户端协议是 `Hysteria2`。

### 入口点

```
订阅: http://74.48.78.17:8080/subscribe
YAML: http://74.48.78.17:8080/hysteria2-client.yaml
分享链接: http://74.48.78.17:8080/hysteria2-link
```

### 主线路参数

| 项目 | 值 |
|------|-------|
| 协议 | `Hysteria2` |
| 主机 | `74-48-78-17.nip.io` |
| 端口 | `8444/udp` |
| TLS SNI | `74-48-78-17.nip.io` |
| 示例本地 socks5 | `127.0.0.1:10888` |

## 为什么这是主线路

在固定服务器地域和当前路径条件下：

- TCP 主线路仅约 `0.1 MB/s`
- Hysteria2 调优后单流可达约 `8-9 MB/s`
- 并行下载通常约 `9-11 MB/s`

因此，Hysteria2 是默认推荐。

## v2rayN 说明

对于 `v2rayN`，无需特别设置 Hysteria 全局值，保持默认即可。

如果导入的节点正确但吞吐量意外差，检查客户端实现和客户端代理设置。

## 订阅同步要求

`/subscribe` 必须始终指向当前主线路。当 Hysteria2 是主线路时，解码 `/subscribe` 必须得到 `hysteria2://...#US-Hysteria2-Main`。如果客户端刷新仍显示 `VLESS + tcp`，首先检查 `/root/vpn-server/xray/html/subscribe` 是否仍包含旧链接，然后检查本地 v2rayN 数据库是否仍保留过期的订阅节点。

## 备用线路

如果需要备用 `VLESS + REALITY` 线路：

- 分享链接：`http://74.48.78.17:8080/reality-link`

`/subscribe` 保留用于当前主线路，不再是 REALITY 备用入口。

## 验收标准

当以下全部为真时，客户端设置被认为是正确的：

- 导入的节点是 Hysteria2。
- 本地 socks5 端口正在监听。
- 通过本地代理访问 `https://api.ipify.org` 返回 `74.48.78.17`。
- 大文件下载速度明显优于 TCP 备用线路。