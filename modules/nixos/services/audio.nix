{ pkgs, ... }:
let
  soundfontPath = "/run/current-system/sw/share/soundfonts/FluidR3_GM2-2.sf2";
  lv2Path = "/run/current-system/sw/lib/lv2";
  vst3Path = "/run/current-system/sw/lib/vst3";
  ladspaPath = "/run/current-system/sw/lib/ladspa";
in {
  # Low-latency audio stack for music applications such as JJazzLab with EWI USB.
  security.rtkit.enable = true;

  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 48000 ];
        "default.clock.quantum" = 128;
        "default.clock.min-quantum" = 64;
        "default.clock.max-quantum" = 256;
      };
    };

    extraConfig.pipewire-pulse."92-low-latency" = {
      "stream.properties" = {
        "node.latency" = "128/48000";
        "resample.quality" = 1;
      };
    };

    wireplumber.enable = true;
  };

  environment.sessionVariables = {
    EWI_SOUNDFONT = soundfontPath;
    LV2_PATH = lv2Path;
    VST3_PATH = vst3Path;
    LADSPA_PATH = ladspaPath;
  };

  environment.systemPackages = with pkgs; [
    alsa-utils
    audacity
    carla
    fluidsynth
    soundfont-fluid
    (pkgs.callPackage ../../../pkgs/jjazzlab { })
    pavucontrol
    qjackctl
    qpwgraph # in favor of helvum
    qsynth

    surge-XT
    helvum
    easyeffects
    (writeShellScriptBin "ewi-carla" ''
      export LV2_PATH="${lv2Path}''${LV2_PATH:+:$LV2_PATH}"
      export VST3_PATH="${vst3Path}''${VST3_PATH:+:$VST3_PATH}"
      export LADSPA_PATH="${ladspaPath}''${LADSPA_PATH:+:$LADSPA_PATH}"
      exec ${carla}/bin/carla "$@"
    '')
    (writeShellScriptBin "ewi-carla-reset" ''
      rm -f "$HOME/.config/falkTX/CarlaPlugins5.conf" \
        "$HOME/.config/falkTX/CarlaDatabase2.conf" \
        "$HOME/.config/falkTX/Carla2.conf" \
        "$HOME/.config/falkTX/CarlaRefresh2.conf"
      export LV2_PATH="${lv2Path}''${LV2_PATH:+:$LV2_PATH}"
      export VST3_PATH="${vst3Path}''${VST3_PATH:+:$VST3_PATH}"
      export LADSPA_PATH="${ladspaPath}''${LADSPA_PATH:+:$LADSPA_PATH}"
      exec ${carla}/bin/carla "$@"
    '')
    (writeShellScriptBin "ewi-carla-refresh" ''
      export LV2_PATH="${lv2Path}''${LV2_PATH:+:$LV2_PATH}"
      export VST3_PATH="${vst3Path}''${VST3_PATH:+:$VST3_PATH}"
      export LADSPA_PATH="${ladspaPath}''${LADSPA_PATH:+:$LADSPA_PATH}"
      export QT_QPA_PLATFORM=offscreen
      exec ${pkgs.python3}/bin/python3 \
        ${carla}/share/carla/carla_database.py \
        --with-libprefix=${carla}
    '')
    (writeShellScriptBin "ewi-fluidsynth" ''
      export LV2_PATH="${lv2Path}''${LV2_PATH:+:$LV2_PATH}"
      export VST3_PATH="${vst3Path}''${VST3_PATH:+:$VST3_PATH}"
      export LADSPA_PATH="${ladspaPath}''${LADSPA_PATH:+:$LADSPA_PATH}"
      exec ${fluidsynth}/bin/fluidsynth \
        --audio-driver=jack \
        --midi-driver=alsa_seq \
        --connect-jack-outputs \
        --no-shell \
        --server \
        --gain=1.0 \
        --sample-rate=48000 \
        --portname="EWI FluidSynth" \
        "${soundfontPath}" \
        "$@"
    '')

  ];
}
