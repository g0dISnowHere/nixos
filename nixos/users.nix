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
    extraGroups = [ "networkmanager" "wheel" "docker" "scanner" ];
    # openssh.authorizedKeys.keys = [
    #   # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
    # ];
  };
    # packages = with pkgs; [
    #   # kate
    # #  thunderbird
    # ];
  }
