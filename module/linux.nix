{ config, pkgs, lib, ... }:
{ script }:

let
  scriptBin = pkgs.writeShellScriptBin "home-manager-secrets-script" ''
    set -euo pipefail
    DRY_RUN_CMD=
    VERBOSE_ARG=
    ${script}
  '';

in
{
  systemd.user.services = {
    "home-manager-secrets" = {
      Unit = {
        Description = "Decrypt home-manager-secrets files";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
      Service = {
        ExecStart = "${scriptBin}/bin/home-manager-secrets-script";
        Environment = "PATH=${lib.makeBinPath [ pkgs.coreutils ]}";
      };
    };
  };
}
