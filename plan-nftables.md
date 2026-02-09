# nftables Migration Plan (Module-Scoped)

## Goal

Switch the firewall backend to nftables while keeping feature modules self-contained. Translate iptables rules to nftables, preserve behavior, and parameterize host-specific interfaces in machine configs.

## Decisions

- Enable nftables centrally in the shared firewall module.
- Keep ICMP subnet fixed but modular.
- Use dedicated nftables tables/chains per feature module.
- Libvirt bridge interfaces are per-host values set in machine configs.
- Assertion should always run and provide a helpful message.
- `trustedInterfaces` should be conditional on interface values.
- Network settings must live only in firewall.nix or the module that needs them.

## Steps

1. **Enable nftables** in modules/nixos/services/firewall.nix, keep current `networking.firewall.allowed*` allowlists.
2. **ICMP rules → nftables** in modules/nixos/services/icmp-ping-lan.nix:
   - Replace iptables `nixos-fw-input`/`nixos-fw-output` rules with nftables rules in a dedicated table/chain.
   - Keep subnet fixed at 192.168.3.0/24.
3. **Libvirt bridge rules → nftables** in modules/nixos/virtualisation/libvirtd.nix:
   - Replace iptables `extraCommands`/`extraStopCommands` with nftables rules.
   - Add module options for `bridgeInterface` and `physicalInterface`.
   - Only emit rules and `trustedInterfaces` when both are set.
4. **Always-on assertion** in modules/nixos/virtualisation/libvirtd.nix:
   - If only one of the two interfaces is set, fail with a message pointing to nixos/machines/*/default.nix (or the relevant machine config).
5. **Bridge sysctls** in modules/nixos/virtualisation/libvirtd.nix:
   - Enable bridge netfilter hooks so nftables can filter bridged traffic (explain in comments).

## Host Configuration

Set per-host interface values in machine configs under nixos/machines:

- Example: nixos/machines/centauri/default.nix
  - `my.libvirt.bridgeInterface = "br0";`
  - `my.libvirt.physicalInterface = "enp0s31f6";`

## Notes

- iptables chains (`nixos-fw-input` / `nixos-fw-output`) are iptables-specific and won’t exist in nftables.
- Keep network settings scoped to the module that uses them.
