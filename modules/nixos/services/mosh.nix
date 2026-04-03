{ ... }: {
  # Mosh keeps remote shells usable across IP changes and brief network loss.
  # Open the standard UDP range on hosts that accept interactive remote logins.
  programs.mosh = {
    enable = true;
    openFirewall = true;
  };
}
