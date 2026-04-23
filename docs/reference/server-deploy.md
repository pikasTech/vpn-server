# 服务器部署

## 范围

本文档涵盖当前默认部署路径：`Hysteria2 + Docker`。`VLESS + REALITY` 仅作为备用保留。

## 前置条件

- Ubuntu 22.04 x86_64
- 已安装 Docker
- 公网 IP 可达
- 工作目录：`/root/vpn-server/`

## 主线路文件布局

- `hysteria2/hysteria`: 服务器二进制文件
- `hysteria2/config.yaml`: 当前服务器配置
- `xray/html/hysteria2-client.yaml`: Hysteria2 YAML 客户端配置
- `xray/html/hysteria2-link`: Hysteria2 明文分享链接
- `xray/html/subscribe`: base64 编码的主线路分享链接
- `xray/nginx.conf`: nginx 分发配置

## 主线路部署步骤

1. 准备 `hysteria2/config.yaml`。
2. 准备 `xray/html/hysteria2-client.yaml`。
3. 准备 `xray/html/hysteria2-link` 和 `xray/html/subscribe`。`/subscribe` 必须是当前主线路分享链接的 base64 编码形式。
4. 启动 Hysteria2：

```bash
docker run -d --name hysteria2 --restart unless-stopped   -p 8444:8444/udp   -v /root/vpn-server/hysteria2:/etc/hysteria   tobyxdd/hysteria server -c /etc/hysteria/config.yaml
```

5. 验证 nginx 发布配置文件和订阅端点：

```bash
curl http://74.48.78.17:8080/hysteria2-client.yaml
curl http://74.48.78.17:8080/hysteria2-link
curl http://74.48.78.17:8080/subscribe | base64 -d
```

## 主线路切换同步规则

当主线路协议、端口、主机名、密码或分享参数变更时，同时更新以下所有内容，以避免客户端继续导入旧协议：

- `/root/vpn-server/hysteria2/config.yaml`: 当前服务器配置。
- `/root/vpn-server/xray/html/hysteria2-client.yaml`: YAML 客户端配置。
- `/root/vpn-server/xray/html/hysteria2-link`: 明文分享链接。
- `/root/vpn-server/xray/html/subscribe`: base64 编码的当前主线路分享链接。

验收规则是解码 `/subscribe` 必须产生当前主线路分享链接；仅确认服务器容器已更改是不够的。

## 基线系统调优

保持以下基线检查可用：

```bash
sysctl net.ipv4.tcp_congestion_control
sysctl net.core.default_qdisc
sysctl net.core.rmem_max net.core.wmem_max
sysctl net.core.rmem_default net.core.wmem_default
```

## 备用说明

如果需要暂时回滚 Hysteria2，继续使用 `xray8443` 作为 `VLESS + REALITY`，但不要将其视为默认线路。

## 验收

```bash
docker ps --format 'table {{.Names}}	{{.Status}}	{{.Ports}}'
ss -tulpn | grep -E ':8444|:8080'
curl http://74.48.78.17:8080/hysteria2-client.yaml
curl http://74.48.78.17:8080/subscribe | base64 -d
```