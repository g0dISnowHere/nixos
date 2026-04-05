{ ... }: {
  environment.etc."ssh/ssh_config.d/99-defaults.conf".text = ''
    Host *
      AddKeysToAgent yes
      Compression yes
      HashKnownHosts yes
      IdentityFile ~/.ssh/id_ed25519
      ServerAliveInterval 60
      ServerAliveCountMax 3
  '';
}
