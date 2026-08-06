# VPN 私有网络（WireGuard + Mihomo）

基于自建服务器 + WireGuard 隧道 + Mihomo 代理的私有网络方案，目标是**在任意新机器上快速部署服务端与客户端**。

## 特性
- **WireGuard 加密隧道**：内核模块 / kmod，虚拟私有网段
- **Mihomo 代理**：只监听隧道 IP，不暴露公网
- **Clash Verge 合并配置**：claude/gpt 走自建节点，海外走美国节点，其余直连
- **模板化 + 变量化**：无硬编码 IP / 密钥；部署时从 `config/vars.env` 读取

## 快速开始

### 服务端
```bash
cd vpn
cp config/vars.env.example config/vars.env   # 填写 SERVER_PUBLIC_ADDR（IPv4/IPv6 均可）
# 上传整个 vpn/ 到服务器（或 git clone），然后：
sudo bash server/deploy.sh     # 装基础软件/swap/防火墙/mihomo
sudo bash server/genkeys.sh    # 生成密钥 + 写服务端配置 + 输出客户端配置
```

> mihomo 二进制需自行放置到 `/usr/local/bin/mihomo`（远程若无法访问 GitHub，本地下载后 scp 上传）。

### 客户端（Mac）
见 `client/README.md`：导入 genkeys.sh 输出的配置连隧道 + 配 Clash Verge。

## 目录结构
```
vpn/
├── README.md                  # 本文件
├── docs/                      # 架构 / 快速开始 / 验证 / 排查
├── config/vars.env.example    # 部署变量模板
├── server/                    # 服务端：deploy.sh / genkeys.sh / mihomo
├── client/                    # 客户端：wg0 模板 / Clash 模板
└── scripts/                   # 辅助脚本
```

## 安全说明
- 仓库**不含密钥/密码/IP**：私钥运行时生成，机场节点用占位符，IP 用变量
- `vars.env`、`*.key`、`output/`、生成的 `*.conf` 已被 `.gitignore` 忽略
- 建议私有仓库

## 验证与排查
见 `docs/verification.md`（三层验证清单）与 `docs/troubleshooting.md`（SELinux/防火墙等常见问题）。
