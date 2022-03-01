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

  home.activation = lib.mkIf cfg.enableForceReload {
    homeManagerSecrets = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
      (
        export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}

        if systemctl --user list-units --full --no-legend -all | grep "home-manager-secrets.service"; then
          systemctl --user restart home-manager-secrets.service
        fi
      )
    '';
  };
}
