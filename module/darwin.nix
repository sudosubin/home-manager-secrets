{ config, pkgs, lib, ... }:
{ script }:

let
  cfg = config.secrets;

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

  home.activation = lib.mkIf cfg.enableForceReload {
    homeManagerSecrets = lib.hm.dag.entryAfter [ "checkLaunchAgents" ] ''
      (
        agent="gui/$UID/${config.launchd.agents.home-manager-secrets.config.Label}"

        if launchctl print "$agent" >/dev/null 2>&1; then
          launchctl kickstart -k "$agent"
        fi
      )
    '';
  };
}
