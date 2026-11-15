{ ... }:
{
  flake.modules.system-manager.arch-vm-base = { pkgs, ... }: {
    nixpkgs.hostPlatform = "x86_64-linux";

    # Required to work on systems other than Ubuntu and Debian
    system-manager.allowAnyDistro = true;

    environment.systemPackages = with pkgs; [
      fastfetch
    ];
  };
}
