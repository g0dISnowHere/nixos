#!/usr/bin/env bash

# Bridge Networking Test Script
# Run this after rebuilding NixOS to verify bridge configuration

echo "=== Bridge Networking Test Script ==="
echo

# Check if bridge exists
echo "1. Checking if bridge br0 exists:"
if ip link show br0 &>/dev/null; then
    echo "✓ Bridge br0 exists"
    ip addr show br0
else
    echo "✗ Bridge br0 not found"
fi
echo

# Check bridge members
echo "2. Checking bridge members:"
if command -v brctl &>/dev/null; then
    brctl show br0
else
    echo "Using ip command instead of brctl:"
    bridge link show master br0
fi
echo

# Check if physical interface is part of bridge
echo "3. Checking if enp0s31f6 is enslaved to br0:"
ip link show enp0s31f6 | grep -q "master br0" && echo "✓ enp0s31f6 is part of br0" || echo "✗ enp0s31f6 is NOT part of br0"
echo

# Check IP configuration
echo "4. IP Configuration:"
echo "Host bridge IP:"
ip addr show br0 | grep "inet "
echo "Physical interface IP (should be none):"
ip addr show enp0s31f6 | grep "inet " || echo "✓ No IP on physical interface"
echo

# Check routing
echo "5. Routing table:"
ip route | grep br0
echo

# Check if IP forwarding is enabled
echo "6. IP Forwarding:"
sysctl net.ipv4.ip_forward
echo

# Check bridge netfilter settings
echo "7. Bridge netfilter settings:"
echo "bridge-nf-call-iptables: $(cat /proc/sys/net/bridge/bridge-nf-call-iptables 2>/dev/null || echo 'N/A')"
echo "bridge-nf-call-ip6tables: $(cat /proc/sys/net/bridge/bridge-nf-call-ip6tables 2>/dev/null || echo 'N/A')"
echo "bridge-nf-call-arptables: $(cat /proc/sys/net/bridge/bridge-nf-call-arptables 2>/dev/null || echo 'N/A')"
echo

# Check libvirt network
echo "8. Libvirt network status:"
if command -v virsh &>/dev/null; then
    virsh net-list --all
    echo
    echo "Bridge network details:"
    virsh net-dumpxml br0 2>/dev/null || echo "br0 network not defined in libvirt"
else
    echo "virsh not available"
fi
echo

# Check firewall rules
echo "9. Relevant firewall rules:"
echo "FORWARD chain rules mentioning br0:"
iptables -L FORWARD -v | grep br0 || echo "No specific br0 rules found"
echo

# Check NetworkManager status
echo "10. NetworkManager unmanaged devices:"
nmcli device status | grep -E "(br0|enp0s31f6)" || echo "Devices not found in NetworkManager"
echo

echo "=== Test complete ==="
echo
echo "To test VM connectivity:"
echo "1. Create a VM using the br0 network in virt-manager"
echo "2. The VM should get an IP from your router's DHCP"
echo "3. You should be able to ping the VM from other devices on your network"
echo "4. The VM should be able to reach the internet"