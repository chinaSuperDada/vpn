#!/usr/bin/env bash
# ============================================================
# 生成服务端/客户端 WireGuard 密钥：
#   1) 写服务端 /etc/wireguard/wg0.conf 并启动隧道
#   2) 输出客户端配置（复制到 Mac 使用）
# 用法：sudo bash server/genkeys.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$SCRIPT_DIR/config/vars.env" ] && source "$SCRIPT_DIR/config/vars.env"

SERVER_PUBLIC_ADDR="${SERVER_PUBLIC_ADDR:?请在 config/vars.env 中设置 SERVER_PUBLIC_ADDR（IPv4 或 IPv6）}"
SERVER_TUN_IP="${SERVER_TUN_IP:-10.8.0.1}"
CLIENT_TUN_IP="${CLIENT_TUN_IP:-10.8.0.2}"
TUNNEL_SUBNET="${TUNNEL_SUBNET:-10.8.0.0/24}"
WG_PORT="${WG_PORT:-51820}"

# IPv6 地址加方括号，IPv4 不加
format_endpoint() {
  case "$1" in
    *:*) echo "[$1]:$WG_PORT" ;;
    *)   echo "$1:$WG_PORT" ;;
  esac
}

umask 077
mkdir -p /etc/wireguard
cd /etc/wireguard

# 生成密钥
wg genkey | tee server_private.key | wg pubkey > server_public.key
wg genkey | tee client_private.key | wg pubkey > client_public.key
chmod 600 *.key

# 写服务端配置
SERVER_PRIVATE_KEY=$(cat server_private.key)
CLIENT_PUBLIC_KEY=$(cat client_public.key)
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = $SERVER_TUN_IP/24
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIVATE_KEY

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $CLIENT_TUN_IP/32
PersistentKeepalive = 25
EOF

systemctl enable wg-quick@wg0 >/dev/null 2>&1 || true
systemctl restart wg-quick@wg0 || true

echo "== 服务端 wg0.conf 已写入并启动 =="
echo ""
echo "===== 以下为客户端配置（保存为 wg0.conf 导入 Mac WireGuard）====="
cat <<EOF
[Interface]
Address = $CLIENT_TUN_IP/24
PrivateKey = $(cat client_private.key)

[Peer]
PublicKey = $(cat server_public.key)
Endpoint = $(format_endpoint "$SERVER_PUBLIC_ADDR")
AllowedIPs = $TUNNEL_SUBNET
PersistentKeepalive = 25
EOF
echo "===== 客户端配置结束 ====="
