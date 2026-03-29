{ ... }: {
  users.users.djoolz.openssh.authorizedKeys.keys = [
    # Primary workstation key used for operator access from centauri.
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJG4h30pgt87nkKeNeF1qNtFv9cj7QkjqD76sZQEiFSf djoolz@centauri-2026-03-28"
    # Mirach's user key for operator access from mirach and other trusted hosts.
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIXA/w+q0MsmIJ8a8HhE4M+qGZbXd8gkpJ4kGPZB48Y"
  ];
}
