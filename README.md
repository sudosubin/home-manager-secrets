# home-manager-secrets

`home-manager-secrets` is a [home-manager](https://github.com/nix-community/home-manager) module for managing secret files.

## Installation

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-secrets = {
      url = "github:sudosubin/home-manager-secrets";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, home-manager-secrets }: {
    homeConfigurations = {
      jdoe = home-manager.lib.homeManagerConfiguration {
        system = "x86_64-linux";
        homeDirectory = "/home/jdoe";
        username = "jdoe";
        configuration.imports = [
          home-manager-secrets.homeManagerModules.home-manager-secrets
          ./home.nix
        ];
      };
    };
  };
}
```

## Usages

There are [more options](./docs/OPTIONS.md) available.

```nix
{ config, ... }:

{
  secrets.identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];

  secrets.file = {
    "foo/bar.txt" = {
      path = "foo-bar-txt";
      source = ./files/bar.txt.age;
      symlinks = [ "${config.xdg.configHome}/foo/bar.txt" ];
    };
  };
}
```

## Credits

This project was written with a lot of influence from [agenix](https://github.com/ryantm/agenix), [agenix#58](https://github.com/ryantm/agenix/pull/58), [homeage](https://github.com/jordanisaacs/homeage).
