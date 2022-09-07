{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    jlink = pkgs.callPackage ./default.nix {};

    connection-type = { swd = "SWD"; jtag = "JTAG"; };
    make-script = { device ? "", fpath ? "", speed ? 4000, addr ? "0x08000000", connection ? connection-type.swd }:
      pkgs.writeTextFile {
        name = "jlink-script";
        text = ''
          device ${device}
          si ${connection}
          speed ${builtins.toString speed}
          loadfile ${fpath},${addr}
          r
          g
          qc
        '';
    };

    flash-script = script:
      pkgs.writeShellApplication {
        name = "flash-jlink";
        text = "${jlink}/bin/JLinkExe -commanderscript ${script}";
        runtimeInputs = [ jlink ];
    };
  in
  {
    inherit jlink connection-type make-script flash-script;
    defaultPackage.${system} = jlink;
  };
}
