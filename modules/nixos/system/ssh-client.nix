_: {
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
      HostName albaldah
      User djoolz
      IdentitiesOnly yes

    Host albaldah-root
      HostName albaldah
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

    # Tailscale SSH on Alhena's WSL instance stalls during ML-KEM key exchange.
    Host alhena alhena.wallaby-clownfish.ts.net
      HostName alhena.wallaby-clownfish.ts.net
      User djoolz
      IdentitiesOnly yes
      KexAlgorithms curve25519-sha256

    Host alhena-root
      HostName alhena.wallaby-clownfish.ts.net
      User root
      IdentitiesOnly yes
      KexAlgorithms curve25519-sha256
  '';
}
