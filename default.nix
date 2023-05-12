{ stdenv
, fetchzip
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
  version = "788b";

  src = fetchzip {
    url = "https://www.segger.com/downloads/jlink/JLink_Linux_V${version}_x86_64.tgz";
    sha256 = "sha256-KqizPJpO746E+jwnPn7H9I8KZ6Pc9CuToYIRlQ24Vbo=";
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

  postPatch = ''
    sed -i '/ACTION/d' 99-jlink.rules
    for exe in *Exe; do
      echo "Patching executable $exe"
      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$exe" \
        --set-rpath ${rpath}:$out/lib "$exe"
    done
    for lib in *.so; do
      echo "Patching library $lib"
      patchelf --set-rpath ${rpath}:$out/lib "$lib"
    done
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,lib/udev/rules.d}
    for exe in $src/*Exe; do
      ln -s $exe $out/bin
    done
    for lib in $src/*.so; do
      ln -s $lib $out/lib
    done
    ln -s $src/99-jlink.rules $out/lib/udev/rules.d
    runHook postInstall
  '';

  meta = with lib; {
    description = "Segger JLink Software Pack";
    homepage = "https://www.segger.com/downloads/jlink/";
    license = licenses.unfree;
    mainProgram = "JLinkExe";
    maintainers = with stdenv.lib.maintainers; [ prtzl ];
    platforms = [ "x86_64-linux" ];
  };
}
