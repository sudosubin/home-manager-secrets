{
  description = "Secrets management for home-manager";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
  };

  outputs = { self, nixpkgs, ... }: {
    homeManagerModules.home-manager-secrets = import ./module;
  };
}
