# 性能故障排除

## 目标

本文档记录了用于区分 VPS 带宽问题、客户端到服务器路径问题和协议栈问题的稳定故障排除方法、调优结论和当前基准。

## 测量模型

始终分离这三个段：

1. VPS 到公网的出口速度
2. 客户端直接到服务器分发端口的速度
3. 客户端通过代理堆栈的速度

如果某一段比其它段慢很多，不要将结果视为通用服务器带宽问题。

## 可重用测试方法

### 1. VPS 自测

用于确认 VPS 本身仍有健康的公网带宽。

```bash
curl -L -o /dev/null -w 'status=%{http_code} time=%{time_total}s speed=%{speed_download}B/s
'   https://cachefly.cachefly.net/50mb.test --max-time 90
```

### 2. 客户端直连服务器测试

用于测量客户端到服务器的原始路径。

```powershell
curl.exe --noproxy '*' -L -o NUL -w "status=%{http_code} time=%{time_total}s speed=%{speed_download}B/s`n"   http://74.48.78.17:8080/speed-100m.bin --max-time 90
```

### 3. 客户端通过代理测试

用于测量实际代理结果。

```powershell
curl.exe --socks5-hostname 127.0.0.1:7890 -L -o NUL -w "status=%{http_code} time=%{time_total}s speed=%{speed_download}B/s`n"   https://cachefly.cachefly.net/50mb.test --max-time 90
```

## 稳定基准结论

当前可重用的结论：

- VPS 本身从公网下载约 `83-99 MB/s`，所以服务器不是瓶颈。
- 客户端从服务器分发端口直接下载在有问题的 TCP 路径上仅约 `0.14-0.15 MB/s`。
- 基于 TCP 的代理测试保持在相同的极低范围，所以弱段是客户端到服务器的路径，而非 VPS 带宽。
- 在相同固定地域和路径上，从基于 TCP 的主线路切换到基于 UDP 的 Hysteria2 是产生数量级改进的唯一变化。

## 主线路调优结果

当前最佳稳定 Hysteria2 策略：

- 服务器端：不要在 `/root/vpn-server/hysteria2/config.yaml` 中设置 `bandwidth`
- 客户端：无需设置 bandwidth，保持默认即可

使用此策略，当前路径通常达到：

- 单流 Hysteria2 下载：约 `8-9 MB/s`
- 并行 Hysteria2 下载：约 `9-11 MB/s`

## 重要的调优发现

以下提炼的发现应指导未来调优：

- 服务器端 `bandwidth.up: 100 mbps` 上限在约 `12.5 MB/s` 处创建实际天花板，限制了聚合下载吞吐量。
- 移除服务器端 `bandwidth` 部分比保留低估的硬限制更好。
- 客户端 bandwidth 参数在当前路径下无显著影响，测试数据显示的不同带宽设置结果属于随机误差。
- 临时的 UDP `443` 测试实例没有明显优于正常的 `8444/udp` 主线路，因此没有稳定证据表明将主线路端口移到 `443/udp` 是值得的。

## 排除的变量

以下因素已检查，不应在没有新证据的情况下重新发现为主解释：

- 从另一个本地网络重新测试没有显著改变吞吐量。
- 服务器地域是固定的，不在当前优化空间内。
- 基本的 Linux 队列和 TCP 设置已使服务器保持合理的基线状态：
  - `net.ipv4.tcp_congestion_control = bbr`
  - `net.core.default_qdisc = fq`
  - `net.core.rmem_max = 67108864`
  - `net.core.wmem_max = 67108864`
  - `net.core.rmem_default = 1048576`
  - `net.core.wmem_default = 1048576`

## 实际决策规则

当速度差时使用这些规则：

- 如果 VPS 自测快但客户端直连服务器下载慢，首先怀疑接入网络、ISP 路径或跨境路径。
- 如果客户端直连服务器下载正常但代理下载慢很多，检查客户端实现和客户端代理设置。
- 如果基于 UDP 的 Hysteria2 比基于 TCP 的测试快很多，优先改变协议而非微调 Linux TCP 旋钮。
- 如果单流速度在此路径上停滞在约 `8-9 MB/s`，不要承诺 `30 MB/s` 而不改变更大的变量，如地域、上游路径或网络环境。

## 建议的后续步骤逻辑

当目标远高于当前基准时，有意义的下一个变量是：

- 不同的本地接入网络或 ISP 路径
- 不同的服务器地域
- 中继或高级传输路径
- 工作负载级并行而非追逐单流限制

在当前约束下，协议选择和适度 Hysteria2 客户端调优已经是主要有效杠杆。