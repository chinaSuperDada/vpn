#!/usr/bin/env bash
# ============================================================
# 生成客户端 wg0.conf（在服务端运行，密钥需已由 genkeys.sh 生成）
# 输出到 output/wg0-client.conf（已被 gitignore 忽略）
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$SCRIPT_DIR/config/vars.env" ] && source "$SCRIPT_DIR/config/vars.env"

SERVER_PUBLIC_ADDR="${SERVER_PUBLIC_ADDR:?请在 config/vars.env 中设置 SERVER_PUBLIC_ADDR（IPv4 或 IPv6）}"
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

mkdir -p "$SCRIPT_DIR/output"
cat > "$SCRIPT_DIR/output/wg0-client.conf" <<EOF
[Interface]
Address = $CLIENT_TUN_IP/24
PrivateKey = $(cat /etc/wireguard/client_private.key)

[Peer]
PublicKey = $(cat /etc/wireguard/server_public.key)
Endpoint = $(format_endpoint "$SERVER_PUBLIC_ADDR")
AllowedIPs = $TUNNEL_SUBNET
PersistentKeepalive = 25
EOF
echo "已生成: $SCRIPT_DIR/output/wg0-client.conf"
