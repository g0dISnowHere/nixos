{ isNixosIntegrated ? false, lib, ... }: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = lib.optionalAttrs (!isNixosIntegrated) {
      "*" = {
        addKeysToAgent = "yes";
        compression = true;
        hashKnownHosts = true;
        identityFile = [ "~/.ssh/id_ed25519" ];
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
      };
    };
  };
}
