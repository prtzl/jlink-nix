{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      flake = {
        nixosModules.default =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          let
            cfg = config.services.jlink;

            package = pkgs.callPackage ./default.nix { };
          in
          {
            options.services.jlink = {
              enable = lib.mkEnableOption "SEGGER J-Link tools";

              installUdev = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Install udev rules for J-Link devices.";
              };
            };

            config = lib.mkIf cfg.enable {
              environment.systemPackages = [ package ];

              services.udev.packages = lib.mkIf cfg.installUdev [ package ];
            };
          };
      };

      perSystem =
        { pkgs, system, ... }:
        {
          packages.default = pkgs.callPackage ./default.nix { };
        };
    };
}

