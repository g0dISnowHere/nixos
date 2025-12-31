# https://github.com/viperML/octoprint-nix/blob/master/modules/octoprint.nix
{ config, pkgs, ... }: {
  services = {
    octoprint = {
      enable = true;
      port = 80;
      # plugins = p: [
      #   p.telegram
      # ];
    };

    #   mjpg-streamer = {
    #     enable = true;
    #     # https://github.com/jacksonliam/mjpg-streamer/blob/master/mjpg-streamer-experimental/plugins/input_uvc/README.md
    #     inputPlugin = "input_uvc.so --fps 1 -timeout 120";
    #     # outputPlugin = "output_http.so --www @www@ --nocommands --port ${toString mjpg-port}";
    #     outputPlugin = "output_http.so --www @www@ --nocommands --port 5050";
    #   };
    # };

  };
  systemd.services.octoprint = {
    serviceConfig = {
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
    };
  };

  networking.firewall = rec {
    allowedTCPPorts = [ 80 5050 ];
    allowedUDPPorts = allowedTCPPorts;
  };
}
