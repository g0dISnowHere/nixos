{ config, pkgs, ... }:

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  # TODO add home-manager
  # https://nix-community.github.io/home-manager/index.xhtml#sec-usage-configuration
  users.users.djoolz = {
    isNormalUser = true;
    description = "djoolz";
    # initialPassword = "correcthorsebatterystaple";
    # TODO: Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
    extraGroups = [ 
      "networkmanager" 
      "wheel" 
      # "docker" 
      # "scanner" 
      # "lp"
      ];
    ## TODO Use multiple layers of encryption for keys! -> password protected ssh keys, more sec key storage (there are some good solutions for this).
    openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCj6auIi/I93XU/FkoLKkHKb7LFwT3XFRxhPzlQ7llEd0+nbWtUgFAgyQYlf/zhs6Wu7+F81HfUch4I5ThfSvKkxOylBWEEipBHrUk4NqDlRwYwf2VRcdwQiznm8xhluZgQ9Y4r/AVFL+/W3HCazRam0s8wDFnQjJ4x9zeoJChgEm+z2UVcLbJBDWA8ml1/+RBTUtVpEqF4hefk2F0slA3J1sd7WG+ij3b8Q0vBxav6X4VF5NlNm6Dz3dxo432UK8phcOp7chOUYlQaou0oBAeQ+7PbUn2JYQN8RqVIWKLaNfTG3Jx/Pk27cyo+d7uC29YLAqCCbSgOjTiZFAStR/8XfWcVqY9tY290XStw5s1mWvSLmZkJI6LeQwlpaHjq2QxnFL/+8gtKmoHxIwtZx35rDTlp/Hal5YnnrB0ULdGDNTx8dPHLF0VSWXyxqXsFW6+YEdbgICkUukf98WF4CIhaHBeLnr12fkd7P7SIbfbRJZQnfM4Xp3gxxwdLYC9/bfiKdgc06CP4F9khZRE3WEhvEo3VvQXfF5tnQ1EMTi06gW0TpzIf/EvKjD6URRtwV58+5OzAkSBObHSCUBdcVKoVCdQn2Z6fqaf94AynPAItYar2TbWXROCNgulOZ35JdMNbQwLYb7QFpIvPi+WDRZImW0HjykegGzAW0U6nwf1tfQ== jojuble@proton.me"
    ];
    # openssh.authorizedKeys.keyfiles = [
    #   ./authorized_keys
    #   ];
    };
    # packages = with pkgs; [
    #   kate
    #   thunderbird
    #   ];
  }
