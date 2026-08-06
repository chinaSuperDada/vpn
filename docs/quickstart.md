# 快速部署指南

## 一、准备

1. 获取一台有**公网 IP** 的服务器（IPv4 或 IPv6 均可；若只有 IPv6，自建节点只能访问 IPv6 站点）
2. 把整个项目上传到服务器：
   ```bash
   # 在本地
   git clone git@github.com:<你的仓库>/vpn.git
   # IPv6 地址需加方括号：
   scp -r vpn root@[${SERVER_PUBLIC_ADDR}]:/root/vpn
   # IPv4 不加方括号：
   # scp -r vpn root@${SERVER_PUBLIC_ADDR}:/root/vpn
   ```

## 二、服务端部署

```bash
# IPv6 用方括号，IPv4 不用：
ssh root@[${SERVER_PUBLIC_ADDR}]   # IPv6
ssh root@${SERVER_PUBLIC_ADDR}     # IPv4

# 1. 配置变量
cd vpn
cp config/vars.env.example config/vars.env
vi config/vars.env        # 填写 SERVER_PUBLIC_ADDR，可按需改隧道网段/端口

# 2. 放置 mihomo 二进制（若 /usr/local/bin/mihomo 不存在）
#    本地下载 mihomo linux-amd64 → scp 上传 → 记得 restorecon

# 3. 一键部署
sudo bash server/deploy.sh

# 4. 生成密钥 + 客户端配置
sudo bash server/genkeys.sh
# 记下输出的【客户端配置】，后面客户端要用
```

## 三、客户端（Mac）

1. **连隧道**：把 genkeys.sh 输出的配置保存为 `wg0.conf`，导入 WireGuard App（或 `sudo wg-quick up wg0`）
2. **验证**：`ping -c 3 ${SERVER_TUN_IP}` 通即 OK
3. **Clash Verge**：
   ```bash
   cd vpn
   cp client/clash-verge.yaml.template client/clash-verge.yaml
   vi client/clash-verge.yaml   # 替换变量 + 填入机场美国节点
   ```
   然后 Clash Verge → 订阅 → 导入 → 从文件导入 → 激活

## 四、完成检查

- 浏览器打开 claude.ai / chatgpt.com（自建节点）
- 打开 google.com / github.com（美国节点）
- 打开 baidu.com / deepseek.com（直连）

详见 `docs/verification.md`。
