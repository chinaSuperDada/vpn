# 客户端部署指南（Mac + Clash Verge）

## 前置
- 服务端已跑完 `server/deploy.sh` + `server/genkeys.sh`（拿到客户端配置）
- Mac 已安装 WireGuard（GUI App 或 `brew install wireguard-tools`）

## 1. 连接隧道

1. 把 `genkeys.sh` 输出的客户端配置保存为 `wg0.conf`
2. **GUI**：WireGuard App → 导入 wg0.conf → 打开
   **CLI**：
   ```bash
   sudo cp wg0.conf /etc/wireguard/wg0.conf
   sudo wg-quick up wg0
   ```
3. 验证：`ping -c 3 ${SERVER_TUN_IP}`（通 = 隧道 OK）

## 2. 开关命令

| 方式 | 开 | 关 |
|------|-----|-----|
| CLI | `sudo wg-quick up wg0` | `sudo wg-quick down wg0` |
| GUI | WireGuard App 点开 | WireGuard App 点关 |

> 隧道只路由隧道网段，不影响日常上网；重启后自动断开，需手动开启。

## 3. Clash Verge 配置

1. 复制 `clash-verge.yaml.template` 为 `clash-verge.yaml`
2. 替换变量：`${SELF_NODE_NAME}`、`${SERVER_TUN_IP}`、`${MIXED_PORT}`
3. **填入你的机场美国节点**（从机场订阅复制 proxies 行 + 在"美国节点"组里列名）
4. Clash Verge → 订阅页 → 导入 → 从文件导入 → 选这个文件 → 激活
5. 代理页选 `自建` 或 `美国节点` → 开系统代理 / TUN

## 4. 效果
- claude.ai / chatgpt.com → 自建节点（IPv6 出口）
- Google/YouTube/GitHub 等海外 → 美国节点（url-test 自动选最快）
- 国内网站 → 直连
