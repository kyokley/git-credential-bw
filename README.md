# Git credential helper for Bitwarden

Retrieve HTTPS Git usernames and passwords from Bitwarden. This flake currently supports `x86_64-linux` only.

## Requirements

Nix with flakes enabled is required for the flake-based installation and development shell. Enable the `nix-command` and `flakes` experimental features if your Nix installation does not already enable them.

## Install from a local checkout

From the repository directory, install the flake's default package:

```sh
nix profile install .
```

Configure Git to use the helper:

```sh
git config --global credential.helper bw
```

Git expands the helper name `bw` to `git-credential-bw`. The packaged helper includes its own `bitwarden-cli` and sets `GIT_CREDENTIAL_BW_CMD` to that `bw` executable. To use the development environment instead, run `nix develop` from the checkout; its shell provides both `git-credential-bw` and `bw`.

## Home Manager

Merge the following into your existing Home Manager flake, keeping your existing inputs and home configuration modules. Replace `/path/to/git-credential-bw` and `YOUR_USER` with your checkout path and Home Manager username:

```nix
{
  inputs.git-credential-bw.url = "path:/path/to/git-credential-bw";

  outputs = { nixpkgs, home-manager, git-credential-bw, ... }: {
    homeConfigurations.YOUR_USER = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        ./home.nix # Your existing home configuration.
        git-credential-bw.homeManagerModules.default
        {
          programs.git.enable = true;
          git-credential-bw.enable = true;
        }
      ];
    };
  };
}
```

The module configures Git to use the flake package's helper.

## Manual installation

For a non-flake installation, put `git-credential-bw` somewhere on your `PATH` (for example, `~/.local/bin/`) and ensure Bitwarden CLI (`bw`) is also on your `PATH`. Then configure Git using the command above. The script can use another `bw` executable by setting `GIT_CREDENTIAL_BW_CMD`.

## Usage and security

Run `git pull` or `git push` against an HTTPS remote to use the helper. Your Bitwarden vault must contain a matching login item with both a username and password.

On a cache miss, the helper handles HTTPS requests with a host by trying `bw unlock --raw`, then `bw login --raw` if unlocking fails. It retrieves the username and password for that host from Bitwarden. It does not handle non-HTTPS requests or requests without a host. No vault naming convention is required by the helper.

The helper caches credentials with `git credential-cache` for 900 seconds (15 minutes) by default. Set `GIT_CREDENTIAL_BW_TIMEOUT` to change the timeout in seconds. The Bitwarden session key is not shared between helper invocations, but cached Git credentials are available in plaintext to users with access to the cache. Use this helper only on systems where you trust people with access.
