let
  sort = builtins.sort builtins.lessThan;

  mkHost = hostname: attrs: attrs // { inherit hostname; };

  hosts = {
    # Current monitored fleet from the monitoring implementation spec.
    albaldah = mkHost "albaldah" {
      host_role = "vps";
      exposure_tier = "public_edge";
      capabilities = [ "docker" "monitoring_baseline" "crowdsec" "traefik" ];
      service_roles = [ "edge" "monitoring" "security" "frontend" ];
      monitoring_enabled = true;
    };

    centauri = mkHost "centauri" {
      host_role = "workstation";
      exposure_tier = "tailscale_only";
      capabilities = [ "docker" "desktop" "monitoring_baseline" ];
      service_roles = [ "frontend" ];
      monitoring_enabled = true;
    };

    mirach = mkHost "mirach" {
      host_role = "local_server";
      exposure_tier = "lan_only";
      capabilities = [ "desktop" "docker" "libvirt" "monitoring_baseline" ];
      service_roles = [ "infra" "vm_host" ];
      monitoring_enabled = true;
    };
  };

  monitoredHosts =
    builtins.filter (host: host.monitoring_enabled) (builtins.attrValues hosts);

  hostNames = sort (map (host: host.hostname) monitoredHosts);
  hasServiceRole = role: host: builtins.elem role host.service_roles;
  hasCapability = capability: host: builtins.elem capability host.capabilities;
  group = predicate:
    sort (map (host: host.hostname) (builtins.filter predicate monitoredHosts));

  validateHost = host:
    assert host ? hostname;
    assert host ? host_role;
    assert host ? exposure_tier;
    assert host ? capabilities;
    assert host ? service_roles;
    assert host ? monitoring_enabled;
    assert !(host.exposure_tier == "public_edge"
      && !hasServiceRole "edge" host);
    true;
in assert builtins.all validateHost monitoredHosts; {
  inherit hosts;

  groups = {
    all_hosts = hostNames;
    workstations = group (host: host.host_role == "workstation");
    local_servers = group (host: host.host_role == "local_server");
    vps_hosts = group (host: host.host_role == "vps");
    public_edge_hosts = group (host: host.exposure_tier == "public_edge");
    docker_hosts = group (hasCapability "docker");
    frontend_hosts = group (hasServiceRole "frontend");
    monitoring_hosts = group (hasServiceRole "monitoring");
    security_hosts = group (hasServiceRole "security");
  };
}
