#!/bin/bash
set -e

echo "=== WireGuard + gretap + bridge setup (Server) ==="

read -p "Public NIC interface name (e.g., eth0): " NIC
read -p "Server public IP (e.g., 212.80.215.165): " SERVER_IP
read -p "WireGuard tunnel IP (e.g., 10.10.10.1/30): " WG_IP
read -p "WireGuard listen port (default 51820): " WG_PORT
WG_PORT=${WG_PORT:-51820}
read -p "Raspberry Pi peer public key: " RASPI_PUB

echo "Installing packages..."
apt update
apt install -y wireguard bridge-utils

echo "Generating WireGuard key..."
umask 077
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
SERVER_PRIV=$(cat /etc/wireguard/server_private.key)

echo "Creating wg0.conf..."
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = $WG_IP
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIV

[Peer]
PublicKey = $RASPI_PUB
AllowedIPs = 10.10.10.2/32
EOF

systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

echo "Creating bridge..."
ip link add br0 type bridge
ip link set br0 up
ip link set $NIC master br0

read -p "Raspberry Pi WireGuard IP (e.g., 10.10.10.2): " PI_WG_IP
echo "Creating gretap interface..."
ip link add wg-gre type gretap local $WG_IP remote $PI_WG_IP dev wg0
ip link set wg-gre master br0
ip link set wg-gre up

echo "✅ Server setup complete!"
echo "Server public key: $(cat /etc/wireguard/server_public.key)"
