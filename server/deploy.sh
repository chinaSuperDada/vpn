#!/usr/bin/env bash
# ============================================================
# 服务端一键部署脚本（Rocky/CentOS 8 / Ubuntu/Debian）
# 用法：先 cp config/vars.env.example config/vars.env 并填写，然后：
#       sudo bash server/deploy.sh
# 注意：mihomo 二进制需自行放置到 /usr/local/bin/mihomo（脚本会检查）
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$SCRIPT_DIR/config/vars.env" ] && source "$SCRIPT_DIR/config/vars.env"

SERVER_PUBLIC_ADDR="${SERVER_PUBLIC_ADDR:?请在 config/vars.env 中设置 SERVER_PUBLIC_ADDR（IPv4 或 IPv6）}"
SERVER_TUN_IP="${SERVER_TUN_IP:-10.8.0.1}"
CLIENT_TUN_IP="${CLIENT_TUN_IP:-10.8.0.2}"
TUNNEL_SUBNET="${TUNNEL_SUBNET:-10.8.0.0/24}"
WG_PORT="${WG_PORT:-51820}"
MIXED_PORT="${MIXED_PORT:-7890}"
SSH_USER="${SSH_USER:-root}"

detect() {
  if command -v apt-get >/dev/null 2>&1; then echo debian
  elif command -v dnf >/dev/null 2>&1; then echo rhel
  elif command -v yum >/dev/null 2>&1; then echo rhel
  else echo unknown; fi
}
DISTRO=$(detect)
echo "== 发行版: $DISTRO =="

# 1. 基础软件
echo "== [1/8] 安装基础软件 =="
case "$DISTRO" in
  rhel)
    dnf install -y epel-release >/dev/null
    dnf install -y wireguard-tools fail2ban firewalld curl wget git vim htop ca-certificates iproute net-tools bind-utils >/dev/null
    ;;
  debian)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update >/dev/null
    apt-get install -y wireguard wireguard-tools ufw fail2ban curl wget git vim htop ca-certificates iproute2 net-tools dnsutils >/dev/null
    ;;
esac

# 2. swap（小内存机器必需）
echo "== [2/8] 添加 swap（如无）=="
if ! swapon --show | grep -q swapfile; then
  fallocate -l 2G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=2048 status=none
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  swapon /swapfile
  grep -q swapfile /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
  echo "  swap 已启用"
fi

# 3. IP 转发
echo "== [3/8] 开启 IP 转发 =="
cat > /etc/sysctl.d/99-wireguard.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sysctl --system >/dev/null

# 4. WireGuard 内核模块
echo "== [4/8] 检查 WireGuard 内核模块 =="
if modprobe wireguard 2>/dev/null; then
  echo "  内核模块 OK"
else
  echo "  内核无模块，尝试安装 kmod（RHEL 系）..."
  case "$DISTRO" in rhel) dnf install -y kmod-wireguard >/dev/null || true ;; esac
  modprobe wireguard 2>/dev/null || echo "  !! 仍无模块：请自行安装 WireGuard 内核支持后重启"
fi

# 5. 防火墙
echo "== [5/8] 配置防火墙 =="
case "$DISTRO" in
  rhel)
    systemctl enable --now firewalld >/dev/null
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-port=$WG_PORT/udp
    firewall-cmd --permanent --add-rich-rule="rule family=\"ipv4\" source address=\"$TUNNEL_SUBNET\" port port=\"$MIXED_PORT\" protocol=\"tcp\" accept"
    firewall-cmd --reload
    ;;
  debian)
    sed -i 's/^IPV6=.*/IPV6=yes/' /etc/default/ufw
    ufw allow OpenSSH
    ufw allow $WG_PORT/udp
    ufw allow from $TUNNEL_SUBNET to any port $MIXED_PORT proto tcp
    ufw --force enable
    ;;
esac

# 6. mihomo 二进制
echo "== [6/8] 检查 mihomo 二进制 =="
if [ ! -x /usr/local/bin/mihomo ]; then
  echo "  !! 未找到 /usr/local/bin/mihomo"
  echo "     请自行获取 mihomo（linux-amd64）放到 /usr/local/bin/mihomo 后重跑本脚本"
  echo "     （提示：远程若无法访问 GitHub，可在本地下载后 scp 上传）"
  exit 1
fi
echo "  mihomo OK: $(/usr/local/bin/mihomo -v 2>&1 | head -1)"

# 7. mihomo 配置 + systemd
echo "== [7/8] 部署 mihomo 配置与 systemd =="
mkdir -p /etc/mihomo
cat > /etc/mihomo/config.yaml <<EOF
mixed-port: $MIXED_PORT
allow-lan: true
bind-address: $SERVER_TUN_IP
mode: rule
log-level: warning
ipv6: true
proxies: []
proxy-groups: []
rules:
  - MATCH,DIRECT
EOF
cp "$SCRIPT_DIR/server/mihomo/mihomo.service" /etc/systemd/system/mihomo.service
systemctl daemon-reload
systemctl enable --now mihomo

# 8. SELinux 修复（RHEL 系，经 /tmp 转发的二进制需要）
echo "== [8/8] SELinux 上下文修复 =="
restorecon -v /usr/local/bin/mihomo 2>/dev/null || true

echo ""
echo "== 服务端部署完成 =="
echo "下一步：运行 server/genkeys.sh 生成密钥与客户端配置"
