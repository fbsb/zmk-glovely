{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pin Zephyr to a version compatible with ZMK.
    zephyr.url = "github:zmkfirmware/zephyr/v3.5.0+zmk-fixes";
    zephyr.flake = false;

    # Zephyr sdk and toolchain.
    zephyr-nix.url = "github:nix-community/zephyr-nix";
    zephyr-nix.inputs.zephyr.follows = "zephyr";
    zephyr-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, zephyr-nix, ... }:
    let
      systems = [
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          zephyr = zephyr-nix.packages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              (zephyr.sdk-0_16.override { targets = [ "arm-zephyr-eabi" ]; })
              zephyr.pythonEnv
              zephyr.hosttools-nix

              pkgs.cmake
              pkgs.dtc
              pkgs.gcc
              pkgs.ninja
              pkgs.tio

              pkgs.just
              pkgs.yq

              # -- Used by just_recipes and west_commands. Most systems already have them. --
              pkgs.gawk
              pkgs.unixtools.column
              pkgs.coreutils # cp, cut, echo, mkdir, sort, tail, tee, uniq, wc
              pkgs.diffutils
              pkgs.findutils # find, xargs
              pkgs.gnugrep
              pkgs.gnused
            ];

            shellHook = ''
              export ZMK_BUILD_DIR=$(pwd)/.build;
              export ZMK_SRC_DIR=$(pwd)/zmk/app;
            '';
          };
        }
      );
    };
}
