{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    pkgs = import nixpkgs {system = "x86_64-linux";};
  in {
    packages.x86_64-linux.git-credential-bw = pkgs.stdenv.mkDerivation {
      src = ./.;

      installPhase = ''
        mkdir -p $out/bin

        cp ./git-credential-bw $out/bin/git-credential-bw
        chmod a+x $out/bin/git-credential-bw
      '';
    };

    homeManagerModules.default = {
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
        home-manager.home.packages = [
          pkgs.bitwarden-cli
        ];
        programs.git = {
          enable = lib.mkDefault true;
          credential = {
            helper = "${self.git-credential-bw}/bin/git-credential-bw";
          };
        };
      };
    };
  };
}
