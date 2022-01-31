# home-manager-secrets

`home-manager-secrets` is a [home-manager](https://github.com/nix-community/home-manager) module for managing secret files.

## Installation

```nix
# flake.nix
{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-secrets = {
      url = "github:sudosubin/home-manager-secrets";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, home-manager-secrets, ...}: {
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
