{
  curl,
  fontconfig,
  freetype,
  gcc,
  lib,
  libICE,
  libSM,
  libX11,
  libXcursor,
  libXext,
  libXfixes,
  libXrandr,
  libXrender,
  runCommand,
  stdenv,
  udev,
  cacert,
}:

stdenv.mkDerivation rec {
  name = "segger-jlink";
  version = "994";

  src =
    runCommand "JLink_Linux_V${version}_x86_64.tgz"
      {
        nativeBuildInputs = [ curl ];
        SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

        outputHashMode = "flat";
        outputHash = "sha256-il22OfTclQZDP/H8uB/NzgSDri5S4uIfXTMqo0f2G0g=";
      }
      ''
        curl -fL \
          -F accept_license_agreement=accepted \
          -F submit=Download+software \
          "https://www.segger.com/downloads/jlink/JLink_Linux_V${version}_x86_64.tgz" \
          -o "$out"
      '';

  rpath = lib.makeLibraryPath [
    fontconfig
    freetype
    libICE
    libSM
    udev
    libX11
    libXcursor
    libXext
    libXfixes
    libXrandr
    libXrender
    gcc
    stdenv.cc.cc.lib
  ];

  phases = [
    "installPhase"
    "fixupPhase"
  ];

  executables = "DDConditionerExe DevProExe JFlashExe JFlashLiteExe JFlashSPICLExe JFlashSPIExe JLinkConfigExe JLinkConnServerExe JLinkExe JLinkGDBServerCLExe JLinkGDBServerExe JLinkGUIServerExe JLinkLicenseManagerExe JLinkRTTClientExe JLinkRTTLoggerExe JLinkRTTViewerExe JLinkRegistrationExe JLinkRemoteServerCLExe JLinkRemoteServerExe JLinkSWOViewerCLExe JLinkSWOViewerExe JLinkUSBWebServerExe JLinkXVCDServerExe JMemExe JRunExe JScopeExe JTAGLoadExe";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/udev/rules.d,opt}
    tar -xvf $src -C $out/opt --strip-components=1
    for exe in ${executables}; do
      ln -s $out/opt/$exe $out/bin
    done
    ln -s $out/opt/99-jlink.rules $out/lib/udev/rules.d
    runHook postInstall
  '';

  postFixup = ''
    for exe in ${executables}; do
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$out/opt/$exe" \
        --set-rpath ${rpath}:$out/opt "$out/opt/$exe"
    done

    for file in $(find $out/opt -maxdepth 1 -name '*.so*'); do
      patchelf --set-rpath ${rpath}:$out/opt $file
    done
    sed -i '/ACTION/d' $out/opt/99-jlink.rules
  '';

  meta = with lib; {
    description = "Segger JLink Software Pack";
    homepage = "https://www.segger.com/downloads/jlink/";
    # license = licenses.unfree;
    maintainers = with stdenv.lib.maintainers; [ prtzl ];
    platforms = [ "x86_64-linux" ];
  };
}
