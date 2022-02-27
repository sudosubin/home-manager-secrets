{ config, pkgs, lib, ... }:
with lib;

let
  inherit (pkgs) stdenv;

  cfg = config.secrets;

  identities = builtins.concatStringsSep " " (map (path: "-i ${path}") cfg.identityPaths);

  createSymlinks = secret: builtins.concatStringsSep "\n" (map
    (symlink:
      let
        source = "${cfg.mount}/${secret.path}";
      in
      ''
        mkdir -p $(dirname ${symlink})
        ln -sf ${source} ${symlink}
      '')
    secret.symlinks);

  decryptSecret = name: secret:
    let
      destination = "${cfg.mount}/${secret.path}";
    in
    ''
      echo "Decrypting secret ${secret.source} to ${destination}"
      TMP_FILE="${destination}.tmp"
      $DRY_RUN_CMD mkdir $VERBOSE_ARG -p $(dirname ${destination})
      (
        $DRY_RUN_CMD umask u=r,g=,o=
        $DRY_RUN_CMD ${cfg.ageBin} --decrypt ${identities} -o "$TMP_FILE" "${secret.source}"
      )
      $DRY_RUN_CMD chmod $VERBOSE_ARG ${secret.mode} "$TMP_FILE"
      $DRY_RUN_CMD chown $VERBOSE_ARG ${secret.owner}:${secret.group} "$TMP_FILE"
      $DRY_RUN_CMD mv $VERBOSE_ARG -f "$TMP_FILE" "${destination}"
      ${createSymlinks secret}
    '';

  secretsScript = builtins.concatStringsSep "\n" (attrsets.mapAttrsToList decryptSecret cfg.file);

  secretsScriptBin = pkgs.writeShellScriptBin "home-manager-secrets-decrypt" ''
    set -euo pipefail
    DRY_RUN_CMD=
    VERBOSE_ARG=
    ${secretsScript}
  '';

  secretType = types.submodule ({ config, ... }: {
    options = {
      path = mkOption {
        type = types.str;
        default = "${config._module.args.name}";
        description = "Path to store decrypted secret file";
      };

      source = mkOption {
        type = types.path;
        description = "Path to the encrypted age file";
      };

      mode = mkOption {
        type = types.str;
        default = "0400";
        description = "Permission of the decrypted secret file";
      };

      owner = mkOption {
        type = types.str;
        default = "$UID";
        description = "User of the decrypted secret file";
      };

      group = mkOption {
        type = types.str;
        default = "$(id -g)";
        description = "Group of the decrypted secret file";
      };

      symlinks = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Paths to create symbolic link";
      };
    };
  });

in
{
  options.secrets = {
    ageBin = mkOption {
      type = types.str;
      default = "${pkgs.rage}/bin/rage";
      example = "\${pkgs.age}/bin/age";
      description = "Path to age binary to use";
    };

    mount = mkOption {
      type = types.str;
      default = "/run/user/$UID/secrets";
      description = "Path to store decrypted secret files";
    };

    identityPaths = mkOption {
      type = types.listOf types.path;
      default = [ ];
      example = "[ \"\${config.home.homeDirectory}/.ssh/id_ed25519\" ]";
      description = "Path of ssh keys to use as identities in age decryption";
    };

    file = mkOption {
      type = types.attrsOf secretType;
      default = { };
      description = "Attrset of secret files";
    };
  };

  config = mkIf (cfg.file != { }) {
    assertions = [{
      assertion = cfg.identityPaths != [ ];
      message = "config.secrets.identityPaths must be set.";
    }];

    # Enabled for darwin
    home.activation = lib.mkIf stdenv.isDarwin {
      homeManagerSecrets = hm.dag.entryAfter [ "writeBoundary" ] secretsScript;
    };

    # Enabled for linux
    systemd.user.services = lib.mkIf stdenv.isLinux {
      "home-manager-secrets" = {
        Unit = {
          Description = "Decrypt home-manager-secrets files";
          PartOf = [ "default.target" ];
        };
        Service = {
          ExecStart = "${secretsScriptBin}/bin/home-manager-secrets-decrypt";
          Environment = "PATH=${makeBinPath [ pkgs.coreutils ]}";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
  };
}
