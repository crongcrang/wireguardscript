#!/bin/bash
set -e

echo "=== WireGuard + gretap + bridge setup (Raspberry Pi) ==="

read -p "LAN interface name (e.g., eth0): " LAN_IF
read -p "WireGuard tunnel IP (e.g., 10.10.10.2/30): " WG_IP
read -p "Server public key: " SERVER_PUB
read -p "Server public IP (e.g., 212.80.215.165): " SERVER_IP
read -p "WireGuard listen port (default 51820): " WG_PORT
WG_PORT=${WG_PORT:-51820}

echo "Installing packages..."
apt update
apt install -y wireguard bridge-utils

echo "Generating WireGuard key..."
umask 077
wg genkey | tee /etc/wireguard/raspi_private.key | wg pubkey > /etc/wireguard/raspi_public.key
RASPI_PRIV=$(cat /etc/wireguard/raspi_private.key)
echo "Your Raspberry Pi public key: $(cat /etc/wireguard/raspi_public.key)"

echo "Creating wg0.conf..."
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = $WG_IP
PrivateKey = $RASPI_PRIV

[Peer]
PublicKey = $SERVER_PUB
Endpoint = $SERVER_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

echo "Creating bridge..."
ip link add br0 type bridge
ip link set br0 up
ip link set $LAN_IF master br0

read -p "Server WireGuard IP (e.g., 10.10.10.1): " SERVER_WG_IP
echo "Creating gretap interface..."
ip link add wg-gre type gretap local $WG_IP remote $SERVER_WG_IP dev wg0
ip link set wg-gre master br0
ip link set wg-gre up

echo "✅ Raspberry Pi setup complete!"
