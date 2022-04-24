{ config, pkgs, lib, ... }@args:
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
      mkdir -p $(dirname ${destination})
      (
        umask u=r,g=,o=
        ${cfg.ageBin} --decrypt ${identities} -o "$TMP_FILE" "${secret.source}"
      )
      chmod ${secret.mode} "$TMP_FILE"
      chown ${secret.owner}:${secret.group} "$TMP_FILE"
      mv -f "$TMP_FILE" "${destination}"
      ${createSymlinks secret}
    '';

  secretsScript = pkgs.writeShellScriptBin "home-manager-secrets-decrypt" ''
    ${builtins.concatStringsSep "\n" (attrsets.mapAttrsToList decryptSecret cfg.file)}
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

    enableForceReload = mkOption {
      type = types.bool;
      default = false;
      description = "Enable force reload on home-manager activation";
    };

    file = mkOption {
      type = types.attrsOf secretType;
      default = { };
      description = "Attrset of secret files";
    };
  };

  config = mkIf (cfg.file != { }) (mkMerge [
    {
      assertions = [{
        assertion = cfg.identityPaths != [ ];
        message = "config.secrets.identityPaths must be set.";
      }];
    }

    (mkIf (stdenv.isDarwin) (import ./darwin.nix args { script = secretsScript; }))
    (mkIf (stdenv.isLinux) (import ./linux.nix args { script = secretsScript; }))
  ]);
}
