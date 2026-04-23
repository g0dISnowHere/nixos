{ ... }: {
  programs.ssh.extraConfig = ''
    AddKeysToAgent yes
    Compression yes
    HashKnownHosts yes
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3

    Host centauri
      HostName centauri
      User djoolz
      IdentitiesOnly yes

    Host albaldah
      HostName 85.215.175.36
      User djoolz
      IdentitiesOnly yes

    Host albaldah-root
      HostName 85.215.175.36
      User root
      IdentitiesOnly yes

    Host mirach
      HostName 192.168.3.223
      User djoolz
      IdentitiesOnly yes

    Host mirach-root
      HostName 192.168.3.223
      User root
      IdentitiesOnly yes

    Host alhena
      HostName 192.168.3.211
      User djoolz
      IdentitiesOnly yes

    Host alhena-root
      HostName 192.168.3.211
      User root
      IdentitiesOnly yes
  '';
}
