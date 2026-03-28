# Preventing Network Drops on NixOS VM Bridges: Root Cause & Solution

## Synopsis
Your wired network connection dropped because the bridge interface (`br0`) lost its carrier when the MAC address changed. This typically happens when a VM starts or stops and attaches to the bridge, causing the MAC to briefly change and the DHCP lease to be lost.

## Key Findings

### 1. Carrier Loss and MAC Flapping
- **Log Evidence:**
  - `dhcpcd` logs show:
    ```
    Jan 09 10:53:03 mirach dhcpcd[982]: br0: carrier lost
    Jan 09 10:53:03 mirach dhcpcd[982]: br0: old hardware address: 3c:97:0e:5b:2d:c2
    Jan 09 10:53:03 mirach dhcpcd[982]: br0: new hardware address: 8a:9b:6c:65:3b:42
    Jan 09 10:53:03 mirach dhcpcd[982]: br0: carrier lost
    Jan 09 10:53:03 mirach dhcpcd[982]: br0: old hardware address: 8a:9b:6c:65:3b:42
    Jan 09 10:53:03 mirach dhcpcd[982]: br0: new hardware address: 3c:97:0e:5b:2d:c2
    ```
  - This caused the bridge to lose its DHCP lease and fall back to a self-assigned IP (169.254.x.x).

### 2. NixOS Configuration
- **Relevant config:** [`libvirtd.nix`](nixos/virtualisation/libvirtd.nix)
  - Bridge and interface setup:
    ```nix
    networking = {
      networkmanager.unmanaged = [ "enp0s25" "br0" ];
      bridges.br0.interfaces = [ "enp0s25" ];
      interfaces.br0.useDHCP = true;
      interfaces.enp0s25.useDHCP = false;
      # ...existing code...
    };
    ```

### 3. Solution: Stable MAC Address
- **Fix applied:**
  - Set a stable MAC address for the bridge to prevent carrier loss:
    ```nix
    localCommands = ''
      ${pkgs.iproute2}/bin/ip link set br0 address 3c:97:0e:5b:2d:c2
    '';
    ```
  - See [`libvirtd.nix`](nixos/virtualisation/libvirtd.nix#L51-L62)

## How to Prevent Recurrence
- Always set a stable MAC address for bridges used by VMs.
- Restart the network service (`sudo systemctl restart network-setup.service`) if the issue recurs, instead of rebooting.
- Rebuild NixOS config after changes: `sudo nixos-rebuild switch`

---
**Summary:**
The network drop was caused by MAC address flapping on the bridge. Setting a fixed MAC address in your NixOS config will prevent this from happening again.
