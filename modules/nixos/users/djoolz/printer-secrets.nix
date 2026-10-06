_:
let
  presetSecret = key: {
    sopsFile = ../../../../secrets/users/djoolz/orca-machine-presets.yaml;
    format = "yaml";
    inherit key;
    owner = "djoolz";
    group = "users";
    mode = "0400";
  };
in
{
  # Printer presets include API credentials, so chezmoi renders runtime secrets.
  sops.secrets = {
    "djoolz-orca-ender3-04" = presetSecret "ender3-04";
    "djoolz-orca-ender3-06" = presetSecret "ender3-06";
    "djoolz-orca-magicianx-04" = presetSecret "magicianx-04";
    "djoolz-orca-magicianx-06" = presetSecret "magicianx-06";
    "djoolz-prusa-presets" = {
      sopsFile = ../../../../secrets/users/djoolz/prusa-machine-presets.yaml;
      format = "yaml";
      key = "presets";
      owner = "djoolz";
      group = "users";
      mode = "0400";
    };
  };
}
