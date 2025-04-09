{
  description = "home-manager-secrets";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";

    lefthook = {
      url = "github:sudosubin/lefthook.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      lefthook,
    }:
    let
      inherit (nixpkgs.lib) genAttrs platforms;
      forAllSystems = f: genAttrs platforms.unix (system: f (import nixpkgs { inherit system; }));

    in
    {
      homeManagerModules.home-manager-secrets = import ./module;

      checks = forAllSystems (pkgs: {
        lefthook-check = lefthook.lib.${pkgs.system}.run {
          src = ./.;
          config = {
            pre-commit.commands = {
              nixfmt = {
                run = "${pkgs.lib.getExe pkgs.nixfmt-rfc-style} {staged_files}";
                glob = "*.nix";
              };
            };
          };
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          inherit (self.checks.${pkgs.system}.lefthook-check) shellHook;
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
