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
  launchd.agents.home-manager-secrets = {
    enable = true;
    config = {
      ProgramArguments = [ "${scriptBin}/bin/home-manager-secrets-script" ];
      RunAtLoad = true;
      EnvironmentVariables = {
        PATH = "${lib.makeBinPath [ pkgs.coreutils ]}";
      };
      StandardOutPath = "${config.xdg.cacheHome}/home-manager-secrets.log";
      StandardErrorPath = "${config.xdg.cacheHome}/home-manager-secrets.log";
    };
  };
}
