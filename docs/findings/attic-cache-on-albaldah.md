# Attic binary cache on Albaldah

## Context

Deploy Attic, self-hosted Nix binary cache, on `albaldah`. Expose it only
through Tailscale at `albaldah.wallaby-clownfish.ts.net`; all fleet hosts use
it as a substituter. Deployments build on the machine that invokes
`deploy-fleet`, so the cache benefits that builder and every configured host.
Use local SQLite metadata and local storage under `/var/lib/atticd/`.

## Implementation

1. Add Attic input to `flake.nix`:

   ```nix
   attic = {
     url = "github:zhaofengli/attic";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   ```

   `flake/lib.nix` already passes the entire `inputs` set to NixOS modules through `specialArgs`; no further plumbing needed.

2. Create `modules/nixos/services/attic-server.nix`. Import `inputs.attic.nixosModules.atticd`; configure `services.atticd` with:

   - `enable` guarded by existence of `secrets/services/attic/server-token.yaml`.
   - `listen = "[::]:8199"`.
   - SQLite: `sqlite:///var/lib/atticd/server.db?mode=rwc`.
   - Local storage: `/var/lib/atticd/storage`.
   - Chunking: NAR threshold 64 KiB; min/average/max chunks 16/64/256 KiB.
   - Garbage collection every 24 hours; default retention 90 days.
   - Set `networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8199 ];`
     in the module. Do not add `8199` to Albaldah's public
     `allowedTCPPorts`.
   - SOPS secret key `attic_server_token`, rendered as:

     ```text
     ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=<secret>
     ```

3. Add service secret scope to `flake/secrets-policy.nix`:

   ```nix
   attic = {
     hosts = [ "albaldah" ];
   };
   ```

   Regenerate policy with:

   ```bash
   scripts/secrets sync-policy
   scripts/secrets validate-policy
   ```

   Generate and encrypt the token:

   ```bash
   TOKEN=$(openssl genrsa -traditional 4096 2>/dev/null | base64 -w0)
   mkdir -p secrets/services/attic
   echo "attic_server_token: \"${TOKEN}\"" > secrets/services/attic/server-token.yaml
   sops --encrypt --in-place secrets/services/attic/server-token.yaml
   sops --decrypt secrets/services/attic/server-token.yaml
   ```

4. Import `../../../modules/nixos/services/attic-server.nix` in `nixos/machines/albaldah/default.nix`.

5. First deployment: evaluate and deploy Albaldah. After deployment, create `main` cache:

   ```bash
   ssh albaldah

   atticd-atticadm make-token --sub "admin" --validity "10y" \
     --push "*" --pull "*" --create-cache "*" --delete-cache "*" \
     --configure-cache "*" --configure-cache-retention "*" \
     --destroy-cache "*" | tee /tmp/admin-token.txt

   nix run github:zhaofengli/attic#attic -- login local http://localhost:8199 "$(cat /tmp/admin-token.txt)"
   nix run github:zhaofengli/attic#attic -- cache create local:main
   nix run github:zhaofengli/attic#attic -- cache info local:main
   rm /tmp/admin-token.txt
   ```

   Copy public signing key shown by `cache info`.

6. Second deployment: add these values to `modules/nixos/system/nix-settings.nix` for all fleet hosts:

   ```nix
   extra-substituters = [
     "https://nix-community.cachix.org"
     "https://hetzner-cache.numtide.com"
     "http://albaldah.wallaby-clownfish.ts.net:8199/main"
   ];

   extra-trusted-public-keys = [
     # Existing keys
     "main:<value from attic cache info>"
   ];
   ```

   Tailscale encrypts cache transport; TLS is not needed.

## Verification

Before deployment:

```bash
nix flake check
nix eval .#nixosConfigurations.albaldah.config.services.atticd.enable
```

After first deployment, on `albaldah`:

```bash
systemctl status atticd
ss -tlnp | grep 8199
```

From another tailnet host, the Tailscale URL must respond; Albaldah's public IP on port `8199` must time out or refuse.

After the second deployment, push and consume a known output:

```bash
# On a host with attic client access
attic push main $(nix build nixpkgs#hello --print-out-paths --no-link)

# On centauri
nix store info --store http://albaldah.wallaby-clownfish.ts.net:8199/main
```

## Operational decisions

- Port: `8199`, avoiding existing Albaldah service ports.
- Database: SQLite, appropriate for one personal cache server.
- Storage: root filesystem at `/var/lib/atticd/storage`; expand storage or reduce retention if disk pressure occurs.
- Cache: one fleet-wide `main` cache.
- Consumer client: no Attic client install required for substituter pulls; use `nix run github:zhaofengli/attic#attic` for administrative cache creation.
