# 验证清单

## 服务端
```bash
sudo wg show                                   # 有 peer + 握手时间
systemctl status mihomo --no-pager | head -5   # active
systemctl status wg-quick@wg0 --no-pager | head -5
# 防火墙（RHEL 系）：
firewall-cmd --list-rich-rules                  # 含 隧道网段 → 代理端口 放行
# 本机代理测试：
curl -x http://${SERVER_TUN_IP}:${MIXED_PORT} -s https://api6.ipify.org  # 返回服务器 IPv6
```

## 客户端（隧道）
```bash
ping -c 3 ${SERVER_TUN_IP}                      # 隧道通
curl -x http://${SERVER_TUN_IP}:${MIXED_PORT} -s https://api6.ipify.org   # 返回远程 IPv6
```

## Clash Verge
| 场景 | 站点 | 预期出站 |
|------|------|----------|
| 自建节点 | claude.ai / chatgpt.com | 正常 |
| 美国节点 | google.com / github.com / youtube.com | 正常 |
| 直连 | baidu.com / deepseek.com | 正常 |

在 Clash Verge「连接」页可查看每一条连接实际走的节点。
