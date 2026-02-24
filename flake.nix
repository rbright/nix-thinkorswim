{
  description = "Standalone Nix package for thinkorswim on Linux/NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      supportedSystems = [ "x86_64-linux" ];
    in
    flake-utils.lib.eachSystem supportedSystems (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "thinkorswim" ];
        };
        thinkorswim = pkgs.callPackage ./package.nix { };
      in
      {
        packages = {
          inherit thinkorswim;
          default = thinkorswim;
        };

        apps = {
          thinkorswim = {
            type = "app";
            program = "${thinkorswim}/bin/thinkorswim";
            meta = {
              description = "Run thinkorswim";
            };
          };
          default = {
            type = "app";
            program = "${thinkorswim}/bin/thinkorswim";
            meta = {
              description = "Run thinkorswim";
            };
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.bash
            pkgs.deadnix
            pkgs.just
            pkgs.nix
            pkgs.nixfmt
            pkgs.prek
            pkgs.ripgrep
            pkgs.shellcheck
            pkgs.statix
          ];
        };

        formatter = pkgs.nixfmt;
      }
    );
}
