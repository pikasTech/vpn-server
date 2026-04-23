# 2026-04-23 REALITY 修复记录

## 结论

- 原来的 Trojan over TLS 在当前本地网络下对 `74.48.78.17:443` 建连不稳定，客户端侧表现为超时。
- 改为 `VLESS + REALITY`，并切换到 `8443` 后，本地 `v2rayN` 已能稳定通过代理访问外网。
- 本地验证结果：通过 `127.0.0.1:7890` 代理访问 `https://api.ipify.org` 返回 `74.48.78.17`。

## 服务端配置

- 容器：`xray8443`
- 配置：`/root/vpn-server/reality/config/config.json`
- 订阅：`/root/vpn-server/xray/html/subscribe`
- 明文链接：`/root/vpn-server/xray/html/reality-link`

## 客户端关键参数

- 地址：`74.48.78.17`
- 端口：`8443`
- UUID：`61c94bb7-f3b2-42e8-aad8-c1458180e91b`
- 传输：`tcp`
- 安全：`reality`
- Flow：`xtls-rprx-vision`
- SNI：`www.microsoft.com`
- 指纹：`chrome`
- Public Key：`sfGFg03US2bNgJ9XYdpI7-W63eG7_19ayIZrA7sluio`
- Short ID：`67b856afffcc5dda`

