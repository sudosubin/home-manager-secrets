{ config, pkgs, lib, ... }:
{ script }:

{
  home.activation = {
    homeManagerSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] script;
  };
}
