# VPN 连接调试记录

## 2026-04-23 调试总结

### 问题概述

客户端（v2rayN）测速显示延迟（200-600ms），但实际连接超时，无法建立有效的 VPN 隧道。

### 调试过程

#### 第一阶段：服务端验证

**服务端 localhost 测试**：
```bash
# 本地 TLS 连接测试
openssl s_client -connect 127.0.0.1:443 -servername 74-48-78-17.nip.io
# 结果：✅ TLS 握手成功，证书有效

# 容器端口检查
ss -tlnp | grep 443
# 结果：✅ docker-proxy 监听 0.0.0.0:443
```

**结论**：服务端本身 TLS 和端口监听正常。

#### 第二阶段：客户端网络测试

**客户端测试命令**（Windows PowerShell/CMD）：
```powershell
# 清除代理设置
set http_proxy=
set https_proxy=

# 测试 HTTP 端口
curl -vk http://74.48.78.17:8080/ --connect-timeout 5

# 测试 HTTPS 端口
curl -vk https://74.48.78.17:443 --connect-timeout 5
```

**测试结果**：
- 端口 8080 (HTTP)：✅ 连接成功，nginx 返回 404（预期行为）
- 端口 443 (HTTPS)：❌ 连接超时

#### 第三阶段：NAT 规则分析

**服务端 iptables 检查**：
```bash
iptables -t nat -L DOCKER -n -v
# 输出：
# pkts bytes target     prot opt in     out source destination
#    18  1016 DNAT       tcp  --  !br-8ce14be658e8 * 0.0.0.0/0 tcp dpt:8080 to:172.19.0.3:8080
#     1    60 DNAT       tcp  --  !br-8ce14be658e8 * 0.0.0.0/0 tcp dpt:443 to:172.19.0.2:443
```

**发现**：端口 8080 有 18 个包，而端口 443 只有 1 个包，说明外部流量能到达 8080 但几乎无法到达 443。

### 客户端日志分析

**v2rayN 客户端日志**（摘录）：
```
2026/04/23 15:32:26 当前延迟: -1 ms，none
2026/04/23 15:32:26 [Warning] core: Xray 26.3.27 started
```

**服务端日志**（同一时间段）：
```
# 没有任何来自 59.72.97.73 的连接记录
```

**结论**：v2rayN 本地代理启动，但从未实际连接到我们的服务器。

### 关键发现

#### 1. 客户端代理设置问题

**症状**：curl 显示 `Uses proxy env variable https_proxy == 'http://127.0.0.1:7890'`

**原因**：v2rayN 的本地 SOCKS/HTTP 代理在拦截所有流量，但代理转发失败

#### 2. v2rayN 端口绑定失败

**错误日志**：
```
Failed to start: app/proxyman/inbound: failed to listen TCP on 7890
> listen tcp 127.0.0.1:7890: bind: An attempt was made to access a socket
> in a way forbidden by its access permissions.
```

**可能原因**：
- 端口 7890 被其他软件占用（Clash、Shadowsocks 等）
- Windows 防火墙或安全软件阻止
- Hyper-V 或 WSL2 占用了端口

#### 3. 协议版本不匹配

**服务端日志**（早期测试）：
```
from 74.48.78.17:55296 rejected proxy/vless/encoding: invalid request version
```

**原因**：客户端发送的协议格式与服务器期望的不匹配

### 测试检查清单

#### 服务端检查

- [x] Docker 容器运行中
- [x] 端口 443、8080 监听中
- [x] TLS 证书有效
- [x] Xray-core 配置正确加载
- [x] localhost TLS 连接正常

#### 客户端检查

- [ ] 关闭所有代理软件（Clash、VPN 等）
- [ ] 清除环境变量 `http_proxy` `https_proxy`
- [ ] 检查 7890 端口是否被占用
- [ ] 确认网络环境（家庭网络 vs 公司网络）
- [ ] 测试手机热点连接

### 客户端测试命令参考

```powershell
# 清除代理（在新 CMD 窗口执行）
set http_proxy=
set https_proxy=

# 测试 HTTP 端口
curl -vk http://74.48.78.17:8080/ --connect-timeout 5

# 测试 HTTPS 端口
curl -vk https://74.48.78.17:443 --connect-timeout 5

# 检查端口占用
netstat -ano | findstr 7890

# 测试 DNS 解析
nslookup 74-48-78-17.nip.io
```

### 网络环境因素

**可能封锁 VPN 流量的场景**：

1. **公司/学校网络**：通常封锁国外流量、VPN 端口
2. **ISP 限制**：某些 ISP 会限流或封锁 VPN 协议
3. **防火墙规则**：客户端或服务端防火墙阻止连接

**建议测试环境**：
- 家庭宽带网络
- 手机 4G/5G 热点
- 海外网络

### 相关配置

**服务端 Xray-core 配置**（Trojan 协议）：
```json
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": 443,
        "protocol": "trojan",
        "settings": {
            "clients": [{
                "password": "12a90b0b-0465-429f-8f36-14b2ebdaef5d",
                "level": 0
            }]
        },
        "streamSettings": {
            "network": "tcp",
            "security": "tls",
            "tlsSettings": {
                "certificates": [{
                    "certificateFile": "/etc/xray/certs/fullchain.pem",
                    "keyFile": "/etc/xray/certs/privkey.pem"
                }],
                "alpn": ["http/1.1"]
            }
        }
    }],
    "outbounds": [{"protocol": "freedom"}]
}
```

**订阅链接**（Base64 编码）：
```
http://74.48.78.17:8080/subscribe
```

解码后：
```
trojan://12a90b0b-0465-429f-8f36-14b2ebdaef5d@74-48-78-17.nip.io:443?encryption=none&security=tls&sni=74-48-78-17.nip.io&alpn=http%2F1.1&fp=chrome&type=tcp#VPN-Trojan
```

### 下一步

1. 在不同网络环境测试（手机热点）
2. 检查客户端防火墙和安全软件
3. 尝试使用 VLESS 协议（REALITY 模式）
4. 考虑使用非标准端口