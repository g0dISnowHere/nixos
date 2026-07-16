{ pkgs, fpSrc }:
let
  inherit (pkgs) fetchFromGitHub lib wrapGAppsNoGuiHook;
  inherit (pkgs.python3Packages)
    buildPythonPackage
    cryptography
    dbus-python
    pyusb
    pyyaml
    pygobject3
    setuptools
    ;
in
buildPythonPackage rec {
  pname = "python-validity";
  version = "0.14";

  pyproject = true;
  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "uunicorn";
    repo = pname;
    rev = version;
    sha256 = "sha256-6NbxeokbGW5yP3g9Q/W3k0JiU6g+qyeZfKfw0nBJ37o=";
  };

  patches = [
    "${fpSrc}/pkgs/python-validity/dbus-service.patch"
    "${fpSrc}/pkgs/python-validity/sensor.py.patch"
    "${fpSrc}/pkgs/python-validity/python-validity-dbus-service.patch"
    "${fpSrc}/pkgs/python-validity/setup.py.patch"
    "${fpSrc}/pkgs/python-validity/validity-sensors-firmware.patch"
    "${fpSrc}/pkgs/python-validity/upload_fwext.py.patch"
  ];

  postPatch = ''
    cp ${fpSrc}/pkgs/python-validity/tmpdir.py validitysensor/tmpdir.py

    substituteInPlace bin/validity-sensors-firmware \
      --replace "'innoextract'" \
                "'${pkgs.innoextract}/bin/innoextract'"

    substituteInPlace debian/python3-validity.service \
      --replace "ExecStart=/usr/lib/python-validity/dbus-service" \
                "ExecStart=$out/bin/python-validity-dbus-service" \
      --replace " --debug" ""
  '';

  nativeBuildInputs = [ wrapGAppsNoGuiHook ];

  propagatedBuildInputs = [
    cryptography
    pyusb
    pyyaml
    dbus-python
    pygobject3
  ];

  postInstall = ''
    install -D -m 644 debian/python3-validity.service \
      $out/lib/systemd/system/python3-validity.service

    install -D -m 644 debian/python3-validity.udev \
      $out/lib/udev/rules.d/60-python-validity.rules

    install -Dm644 LICENSE \
      $out/share/licenses/${pname}/LICENSE
  '';

  pythonImportsCheck = [ "validitysensor" ];

  meta = with lib; {
    description = "Validity fingerprint sensor driver";
    homepage = "https://github.com/uunicorn/python-validity";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
