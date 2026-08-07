#!/usr/bin/env bash
# ============================================================
# 添加一个新客户端 peer（手机/平板/电脑）
# 用法：sudo bash server/add-peer.sh <设备名> <设备隧道IP>
#   例：sudo bash server/add-peer.sh android 10.8.0.3
# 效果：生成该设备密钥 → 追加 [Peer] 到 wg0.conf → 重启隧道
#       → 输出该设备的客户端配置（保存/扫码导入）
# ============================================================
set -euo pipefail

NAME="${1:?用法: sudo bash server/add-peer.sh <设备名> <设备隧道IP>}"
CLIENT_IP="${2:?用法: sudo bash server/add-peer.sh <设备名> <设备隧道IP>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$SCRIPT_DIR/config/vars.env" ] && source "$SCRIPT_DIR/config/vars.env"

SERVER_PUBLIC_ADDR="${SERVER_PUBLIC_ADDR:?请在 config/vars.env 中设置 SERVER_PUBLIC_ADDR}"
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
cd /etc/wireguard

# 生成该设备密钥（已存在则不覆盖）
if [ ! -f "${NAME}_private.key" ]; then
  wg genkey | tee "${NAME}_private.key" | wg pubkey > "${NAME}_public.key"
  chmod 600 "${NAME}_private.key" "${NAME}_public.key"
fi
PUB=$(cat "${NAME}_public.key")

# 追加 peer（避免重复）
if ! grep -q "$PUB" wg0.conf; then
  cat >> wg0.conf <<EOF

[Peer]
PublicKey = $PUB
AllowedIPs = $CLIENT_IP/32
PersistentKeepalive = 25
EOF
fi

systemctl restart wg-quick@wg0 || true

echo "== 已为 [$NAME] 添加 peer ($CLIENT_IP) =="
echo "== 当前 peer 列表 =="
wg show | grep -E "peer|allowed ips"
echo
echo "===== 客户端配置（保存/扫码导入 $NAME 设备）====="
cat <<EOF
[Interface]
Address = $CLIENT_IP/24
PrivateKey = $(cat "${NAME}_private.key")

[Peer]
PublicKey = $(cat server_public.key)
Endpoint = $(format_endpoint "$SERVER_PUBLIC_ADDR")
AllowedIPs = $TUNNEL_SUBNET
PersistentKeepalive = 25
EOF
echo "===== 客户端配置结束 ====="
