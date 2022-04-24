<!-- markdownlint-disable MD001 MD012 -->

# Options

**`secrets.ageBin`**

- type: `types.str`
- default: `${pkgs.rage}/bin/rage`
- example: `${pkgs.age}/bin/age`
- description: Path to age binary to use


**`secrets.mount`**

- type: `types.str`
- default: `/run/user/$UID/secrets`
- description: Path to store decrypted secret files


**`secrets.identityPaths`**

- type: `types.listOf types.path`
- default: `[ ]`
- example: `[ "${config.home.homeDirectory}/.ssh/id_ed25519" ]`
- description: Path of ssh keys to use as identities in age decryption


**`secrets.enableForceReload`**

- type: `types.bool`
- default: `false`
- description: Enable force reload on home-manager activation


**`secrets.file`**

- type: `types.attrsOf secretType`
- default: `{ }`
- description: Attrset of secret files


**`secrets.file.<name>`**

- type: `secretType`
- description: Name of the secret file (not important)


**`secrets.file.<name>.path`**

- type: `types.str`
- default: `${config._module.args.name}` (`name`)
- description: Path to store decrypted secret file


**`secrets.file.<name>.source`**

- type: `types.path`
- description: Path to the encrypted age file


**`secrets.file.<name>.mode`**

- type: `types.str`
- default: `0400`
- description: Permission of the decrypted secret file


**`secrets.file.<name>.owner`**

- type: `types.str`
- default: `$UID`
- description: User of the decrypted secret file


**`secrets.file.<name>.group`**

- type: `types.str`
- default: `$(id -g)`
- description: Group of the decrypted secret file


**`secrets.file.<name>.symlinks`**

- type: `types.listOf types.str`
- default: `[ ]`
- description: Paths to create symbolic link
