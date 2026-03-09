{ lib, stdenvNoCC, fetchurl, autoPatchelfHook, copyDesktopItems, makeDesktopItem
, makeWrapper, alsa-lib, atk, cairo, cups, dbus, expat, fontconfig, freetype
, gdk-pixbuf, glib, gtk3, libX11, libXcomposite, libXcursor, libXdamage, libXext
, libXfixes, libXi, libXinerama, libXrandr, libXrender, libXtst, libdrm
, libglvnd, libxkbcommon, mesa, nspr, nss, pango, xorg, zlib, }:

stdenvNoCC.mkDerivation rec {
  pname = "jjazzlab";
  version = "5.1";

  src = fetchurl {
    url =
      "https://github.com/jjazzboss/JJazzLab/releases/download/${version}/JJazzLab-${version}-linux-x64.tar.xz";
    hash = "sha256-/XDmmu7oI0yO9Gkwb32k30/iyJqjPSuKps5Agfn2iIY=";
  };

  nativeBuildInputs = [ autoPatchelfHook copyDesktopItems makeWrapper ];

  buildInputs = [
    alsa-lib
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libX11
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXinerama
    libXrandr
    libXrender
    libXtst
    libdrm
    libglvnd
    libxkbcommon
    mesa
    nspr
    nss
    pango
    xorg.libXxf86vm
    zlib
  ];

  sourceRoot = "JJazzLab-${version}";

  desktopItems = [
    (makeDesktopItem {
      name = "jjazzlab";
      desktopName = "JJazzLab";
      comment = "Chord-based accompaniment and practice tool";
      exec = "jjazzlab %F";
      icon = "jjazzlab";
      categories = [ "AudioVideo" "Audio" "Midi" "Music" ];
      startupWMClass = "jjazzlab";
      terminal = false;
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/jjazzlab"
    cp -R . "$out/share/jjazzlab/"

    mkdir -p "$out/bin"
    makeWrapper "$out/share/jjazzlab/bin/jjazzlab" "$out/bin/jjazzlab" \
      --set JJAZZLAB_HOME "$out/share/jjazzlab" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"

    mkdir -p "$out/share/pixmaps"
    if [ -f "$out/share/jjazzlab/jjazzlab.png" ]; then
      cp "$out/share/jjazzlab/jjazzlab.png" "$out/share/pixmaps/jjazzlab.png"
    fi

    runHook postInstall
  '';

  meta = {
    description = "Jazz accompaniment and improvisation software";
    homepage = "https://www.jjazzlab.org/";
    license = lib.licenses.lgpl3Only;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "jjazzlab";
  };
}
