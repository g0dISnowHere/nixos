{ ... }:
let ageKeyFile = "/var/lib/sops-nix/key.txt";
in {
  sops = {
    defaultSopsFormat = "yaml";

    # Keep a dedicated machine-local age identity for sops-nix so each host can
    # decrypt repo-managed secrets during activation without depending on SSH
    # host keys or user-managed keys.
    age = {
      generateKey = true;
      keyFile = ageKeyFile;
    };
  };
}
