{
  description = "CeTZ: ein Typst Zeichenpaket - A library for drawing stuff with Typst.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/flake-utils";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      with pkgs;
      rec {
        packages.cetz = pkgs.rustPlatform.buildRustPackage {
          pname = "cetz";
          version = "0.1.0";

          src = ./cetz-core; # flake root

          cargoLock = {
            lockFile = ./cetz-core/Cargo.lock;
          };

          nativeBuildInputs = with pkgs; [
            pkg-config
            llvmPackages.bintools
          ];
          buildInputs = [ just ];
        };

        packages.default = packages.cetz;
      }
    );
}
