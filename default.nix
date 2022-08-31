{
  stdenv
, fetchurl
, fontconfig
, freetype
, lib
, libICE
, libSM
, udev
, libX11
, libXcursor
, libXext
, libXfixes
, libXrandr
, libXrender
}:

stdenv.mkDerivation rec {
  name = "segger-jlink";
  version = "770c";
  
  src = fetchurl {
    url = "https://www.segger.com/downloads/jlink/JLink_Linux_V${version}_x86_64.tgz";
    sha256 = "sha256-O+YeDuVquJ2Q1a5AVd/iq9mTpmKfG6cjulb2qY2IYy8=";
    netrcPhase = ''
      curlOpts="-X POST -F accept_license_agreement=accepted -F submit=Download+software $curlOpts"
    '';
  };

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
  ] + ":${stdenv.cc.cc.lib}/lib64";

  phases = [ "installPhase" "fixupPhase" ];

  executables = "JFlashExe JFlashLiteExe JFlashSPICLExe JFlashSPIExe JLinkConfigExe JLinkExe JLinkGDBServerCLExe JLinkGDBServerExe JLinkGUIServerExe JLinkLicenseManagerExe JLinkRegistrationExe JLinkRemoteServerCLExe JLinkRemoteServerExe JLinkRTTClientExe JLinkRTTLoggerExe JLinkRTTViewerExe JLinkSTM32Exe JLinkSWOViewerCLExe JLinkSWOViewerExe JMemExe JRunExe JTAGLoadExe";

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
    homepage = https://www.segger.com/downloads/jlink/;
    license = licenses.unfree;
    maintainers = with stdenv.lib.maintainers; [ prtzl ];
    platforms = [ "x86_64-linux" ];
  };
}
