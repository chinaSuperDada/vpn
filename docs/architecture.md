# 架构设计

## 拓扑

```
               公网 IP（传输层，IPv4/IPv6 均可）
  Mac ◀═══════ WireGuard 加密隧道 ═══════▶ 远程服务器
  （客户端）                            （服务端 wg0）
  隧道 IP: ${CLIENT_TUN_IP}              隧道 IP: ${SERVER_TUN_IP}
  ─────────────────────────────────────────
  隧道虚拟私有段: ${TUNNEL_SUBNET}
  代理: 远程 mihomo 监听 ${SERVER_TUN_IP}:${MIXED_PORT}（仅隧道）
```

## 地址规划

| 项 | 值 | 说明 |
|----|-----|------|
| 隧道网段 | `${TUNNEL_SUBNET}` | 虚拟私有段，仅存在于隧道内部 |
| 服务端隧道 IP | `${SERVER_TUN_IP}` | 服务端 wg0 接口 |
| 客户端隧道 IP | `${CLIENT_TUN_IP}` | 客户端接口 |
| 公网传输层 | `${SERVER_PUBLIC_ADDR}` | 远程公网出口（IPv4 或 IPv6）|
| WireGuard 端口 | `${WG_PORT}` / udp | 公网入站 |
| mihomo 代理 | `${SERVER_TUN_IP}:${MIXED_PORT}` | 只绑隧道 IP |

## 技术选型

| 组件 | 选择 | 理由 |
|------|------|------|
| 隧道 | WireGuard（内核模块 / kmod）| 轻量、加密、性能好 |
| 代理 | Mihomo（Clash 核心）| 与 Clash Verge 生态兼容 |
| 防火墙 | firewalld / ufw | 只放行隧道网段访问代理端口 |

## 关键设计决策

1. **隧道只路由 `${TUNNEL_SUBNET}`**：不劫持日常上网流量。
2. **代理只监听隧道 IP**：公网访问不到代理端口，安全。
3. **出口能力取决于服务器**：有 IPv4 则可访问全部站点；只有 IPv6 则只能访问 IPv6 站点，海外 IPv4 站点走机场美国节点。
4. **客户端无开机自启**：重启后隧道自动断开，人工控制。
