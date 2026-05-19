{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      perSystem = {pkgs, lib, ...}: let
        lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
        version = builtins.substring 0 8 lastModifiedDate;
        bitwarden-cli = pkgs.bitwarden-cli.overrideAttrs (oldAttrs: rec {
          version = "2026.2.0";
          src = pkgs.fetchFromGitHub {
            owner = "bitwarden";
            repo = "clients";
            tag = "cli-v${version}";
            hash = "sha256-BiL9ugimdDKIzIoehGqdBfJkTOjbOMl8XV+0g/aGS/k=";
          };

          postPatch = ''
            # remove code under unfree license
            rm -r bitwarden_license
          '';

          npmDepsHash = "sha256-BfGoqyUKSKkkfT9PVmBWs7eTPllBnRM53S8yU0OgDw0=";
          npmDeps = pkgs.fetchNpmDeps {
            inherit src postPatch;
            name = "bitwarden-cli-${version}-npm-deps";
            hash = "sha256-BfGoqyUKSKkkfT9PVmBWs7eTPllBnRM53S8yU0OgDw0=";
            fetcherVersion = 2;
          };
        });
      in {
        packages = {
          git-credential-bw = pkgs.stdenv.mkDerivation {
            pname = "git-credential-bw";
            inherit version;
            src = ./.;

            nativeBuildInputs = [
              pkgs.makeWrapper
            ];
            buildInputs = [
              bitwarden-cli
            ];
            installPhase = ''
              mkdir -p $out/bin

              cp ./git-credential-bw $out/bin/git-credential-bw
              chmod a+x $out/bin/git-credential-bw
              wrapProgram $out/bin/git-credential-bw \
                --set GIT_CREDENTIAL_BW_CMD "${bitwarden-cli}/bin/bw"
            '';
          };
          default = self.packages.${pkgs.stdenv.hostPlatform.system}.git-credential-bw;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            self.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
        };
      };

      flake.homeManagerModules.default = {
        config,
        lib,
        pkgs,
        ...
      }: {
        options.git-credential-bw = {
          enable = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether to enable the scm-helpers service
            '';
          };
        };

        config = lib.mkIf config.git-credential-bw.enable {
          programs.git = {
            settings = {
              credential = {
                helper = "${self.packages.${pkgs.stdenv.hostPlatform.system}.git-credential-bw}/bin/git-credential-bw";
              };
            };
          };
        };
      };
    };
}
