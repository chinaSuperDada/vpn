# 故障排查

| 现象 | 原因 | 解决 |
|------|------|------|
| mihomo systemd 启动报 `203/EXEC` | SELinux 上下文错误（经 /tmp 转发的二进制带 `user_tmp_t`）| `restorecon /usr/local/bin/mihomo` |
| 客户端经隧道访问代理端口失败 | 防火墙未放行 | 重跑 deploy.sh 的防火墙步骤，或手动加 rich 规则（仅隧道网段）|
| `ifconfig wg0` 找不到 | GUI App 建的接口叫 `utunX` | `ifconfig \| grep ${CLIENT_TUN_IP}` 查实际接口 |
| 某些海外网站打不开 | 服务器只有 IPv6，无法访问 IPv4-only 站点 | 改 Clash 规则让其走美国节点；或给服务器配 IPv4 |
| dnf 安装被 OOM 杀 | 内存小、无 swap | 先加 swap（deploy.sh 已含）|
| 重启后 IPv6 地址变了 | SLAAC/临时地址 | 用稳定地址（MAC 派生 EUI-64）；重启后 `ip -6 addr` 确认 |

## 常用手动修复命令

放行隧道网段访问代理端口（RHEL 系）：
```bash
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="${TUNNEL_SUBNET}" port port="${MIXED_PORT}" protocol="tcp" accept'
firewall-cmd --reload
```

SELinux 修复：
```bash
restorecon -v /usr/local/bin/mihomo
```
