{
  isNixosIntegrated ? false,
  lib,
  ...
}:
{
  programs.ssh = {
    enable = !isNixosIntegrated;
    enableDefaultConfig = false;
    settings = lib.optionalAttrs (!isNixosIntegrated) {
      "*" = {
        AddKeysToAgent = "yes";
        Compression = true;
        HashKnownHosts = true;
        IdentityFile = [ "~/.ssh/id_ed25519" ];
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
      };
    };
  };
}
