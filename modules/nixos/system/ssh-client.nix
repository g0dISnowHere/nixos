{ ... }: {
  programs.ssh.extraConfig = ''
    AddKeysToAgent yes
    Compression yes
    HashKnownHosts yes
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
  '';
}
