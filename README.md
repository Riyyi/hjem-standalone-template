# Hjem Standalone Template

Small Dendritic Hjem template, to use on any systemd-based distro via System Manager.

## How it works

There are a few parts into making this work.

```nix
# Make `flake.modules` available, for using the Dendritic pattern
imports = [ inputs.flake-parts.flakeModules.modules ];

# Enable System Manager on distros other than Ubuntu and Debian
system-manager.allowAnyDistro = true;

# Import the regular Hjem NixOS module
modules = [ inputs.hjem.nixosModules.default ];

# Custom module; system-manager compatibility tweaks for Hjem's NixOS module
modules = [ self.modules.system-manager.hjem-system-manager ];

```

## Build

Assuming your host is called `arch-vm`, otherwise replace `$HOST` in the command.

```sh
nix run nixpkgs#system-manager -- switch --flake .#$HOST --sudo
```

## Allow Numtide cache

Following additional settings were required to suppress some warnings.

```sh
$ cat /etc/nix/nix.custom.conf
# Written by https://github.com/DeterminateSystems/nix-installer.
# The contents below are based on options specified at installation time.

extra-substituters = https://cache.numtide.com/
trusted-users = root myuser
```

Vanilla Nix uses `/etc/nix/nix.conf`, above file is for Determinite Nix.
