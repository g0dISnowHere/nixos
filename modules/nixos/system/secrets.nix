{ ... }:
let ageKeyFile = "/var/lib/sops-nix/key.txt";
in {
  sops = {
    defaultSopsFormat = "yaml";

    # Generate a stable host-local age identity on first activation so each
    # machine can decrypt repo-managed secrets after bootstrap.
    age = {
      generateKey = true;
      keyFile = ageKeyFile;
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };
}
