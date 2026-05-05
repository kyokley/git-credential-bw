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

      perSystem = {pkgs, ...}: let
        lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
        version = builtins.substring 0 8 lastModifiedDate;
      in {
        packages.git-credential-bw = pkgs.stdenv.mkDerivation {
          pname = "git-credential-bw";
          inherit version;
          src = ./.;

          nativeBuildInputs = [
            pkgs.makeWrapper
          ];
          buildInputs = [
            pkgs.bitwarden-cli
          ];
          installPhase = ''
            mkdir -p $out/bin

            cp ./git-credential-bw $out/bin/git-credential-bw
            chmod a+x $out/bin/git-credential-bw
            wrapProgram $out/bin/git-credential-bw \
              --set GIT_CREDENTIAL_BW_CMD "${pkgs.bitwarden-cli}/bin/bw"
          '';
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
