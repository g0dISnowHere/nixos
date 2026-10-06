_: {
  # chezmoi reads this runtime file; plaintext never enters its source repository.
  sops.secrets."djoolz-gh-hosts" = {
    sopsFile = ../../../../secrets/users/djoolz/chezmoi.yaml;
    format = "yaml";
    key = "ghHosts";
    owner = "djoolz";
    group = "users";
    mode = "0400";
  };
  sops.secrets."djoolz-opencode-auth" = {
    sopsFile = ../../../../secrets/users/djoolz/chezmoi.yaml;
    format = "yaml";
    key = "opencodeAuth";
    owner = "djoolz";
    group = "users";
    mode = "0400";
  };
}
