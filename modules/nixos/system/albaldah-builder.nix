_: {
  programs.ssh.knownHosts."albaldah.wallaby-clownfish.ts.net".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtyFB+Q142gsgFVtPPt7tOGurBMTSvcHvgRReQnOxyH root@albaldah";

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "albaldah.wallaby-clownfish.ts.net";
        sshUser = "root";
        protocol = "ssh-ng";
        system = "x86_64-linux";
        maxJobs = 3;
        speedFactor = 100;
        supportedFeatures = [ "big-parallel" ];
      }
    ];

    settings.builders-use-substitutes = true;
  };
}
