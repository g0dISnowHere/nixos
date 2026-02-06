# Bridge Networking Fix for Libvirtd

This document explains the issues with your original libvirtd bridge configuration and the fixes applied.

## Issues Found

### 1. NetworkManager Conflict
- **Problem**: [`networking.nix`](../networking.nix) had NetworkManager enabled but the unmanaged interfaces were commented out
- **Impact**: NetworkManager was trying to manage `br0` and `enp0s31f6`, conflicting with the manual bridge setup
- **Fix**: Uncommented the `networkmanager.unmanaged = [ "br0" "enp0s31f6" ];` line

### 2. Missing Firewall Rules
- **Problem**: Bridge traffic wasn't allowed through the firewall
- **Impact**: VMs couldn't communicate with the host network or internet
- **Fix**: Added bridge-specific firewall rules in [`firewall.nix`](../firewall.nix):
  - Made `br0` a trusted interface
  - Added FORWARD rules for bridge traffic
  - Added rules for bridge-to-physical interface communication

### 3. Missing Kernel Configuration
- **Problem**: Bridge networking kernel modules and sysctl settings weren't configured
- **Impact**: Bridge networking didn't work optimally
- **Fix**: Added to [`libvirtd.nix`](libvirtd.nix):
  - IP forwarding: `net.ipv4.ip_forward = 1`
  - Disabled bridge netfilter (prevents double-filtering): `bridge-nf-call-*tables = 0`
  - Loaded bridge kernel modules: `bridge` and `br_netfilter`

### 4. Configuration Duplication
- **Problem**: Firewall ports were defined in both files
- **Impact**: Configuration inconsistency
- **Fix**: Consolidated all firewall configuration in [`firewall.nix`](../firewall.nix)

## Applied Changes

### [`networking.nix`](../networking.nix)
```nix
# Uncommented this line:
networkmanager.unmanaged = [ "br0" "enp0s31f6" ];
```

### [`firewall.nix`](../firewall.nix)
```nix
networking.firewall = {
  # ... existing config ...
  
  # Allow bridge traffic for VM networking
  trustedInterfaces = [ "br0" ];
  
  # Bridge networking requires these rules
  extraCommands = ''
    # Allow traffic through bridge
    iptables -I FORWARD -i br0 -j ACCEPT
    iptables -I FORWARD -o br0 -j ACCEPT
    
    # Allow bridge to communicate with physical interface
    iptables -I FORWARD -i br0 -o enp0s31f6 -j ACCEPT
    iptables -I FORWARD -i enp0s31f6 -o br0 -j ACCEPT
  '';
  
  extraStopCommands = ''
    # Clean up bridge rules on firewall stop
    iptables -D FORWARD -i br0 -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -o br0 -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -i br0 -o enp0s31f6 -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -i enp0s31f6 -o br0 -j ACCEPT 2>/dev/null || true
  '';
};
```

### [`libvirtd.nix`](libvirtd.nix)
```nix
# Enable bridge kernel modules and IP forwarding
boot.kernel.sysctl = {
  "net.ipv4.ip_forward" = 1;
  "net.bridge.bridge-nf-call-iptables" = 0;
  "net.bridge.bridge-nf-call-ip6tables" = 0;
  "net.bridge.bridge-nf-call-arptables" = 0;
};

# Load bridge kernel modules
boot.kernelModules = [ "bridge" "br_netfilter" ];
```

## Next Steps

1. **Rebuild your NixOS configuration**:
   ```bash
   sudo nixos-rebuild switch
   ```

2. **Run the test script** to verify the configuration:
   ```bash
   ./mine/nixos/virtualisation/test-bridge-networking.sh
   ```

3. **Test VM connectivity**:
   - Create a new VM in virt-manager
   - Configure it to use the "br0" network
   - The VM should receive an IP from your router's DHCP server
   - Test internet connectivity from within the VM
   - Test connectivity to the VM from other devices on your network

## Expected Behavior After Fix

- **Host**: Gets its own IP from router DHCP on `br0` interface
- **VM**: Gets its own IP from router DHCP (different from host)
- **Network access**: VM can reach internet and be reached from your network
- **Physical interface**: `enp0s31f6` has no IP (bridge takes over)

## Troubleshooting

If you still have issues after applying these fixes:

1. Check the test script output for any red flags
2. Verify your router supports multiple DHCP clients on the same physical port
3. Check if your switch/router has any security features blocking bridge traffic
4. Ensure your VM is configured to use the "br0" network in virt-manager

## Additional Notes

- The bridge configuration uses your physical network, so VMs appear as separate devices on your LAN
- This is different from NAT networking where VMs share the host's IP
- Make sure your router has enough DHCP addresses available for your VMs