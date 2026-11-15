{ inputs, ... }:
{
  flake.modules.system-manager.hjem-system-manager = { lib, pkgs, config, ... }:
    let
      hjemPkg = inputs.hjem.packages.${pkgs.stdenv.hostPlatform.system}.hjem;

      hjemLinker = pkgs.writeShellScriptBin "hjem-linker" ''
        set -e
        cmd="$1"
        new_manifest="$2"

        user=$(basename "$new_manifest" | sed 's/^manifest-\(.*\)\.json$/\1/')
        state="/var/lib/hjem/manifest-$user.json"

        case "$cmd" in
          activate|diff)
            # Mirror the original NixOS module: use hjem's built-in linker
            # (via `internal activate`) and let hjem-update-state@ write the
            # state file as root later.
            exec ${hjemPkg}/bin/hjem internal activate \
              --skip-state-update \
              --manifest "$new_manifest" \
              --state "$state" \
              --prefix ".backup-" \
              --json
            ;;
          *)
            echo "hjem-linker: unknown command '$cmd'" >&2
            exit 1
            ;;
        esac
      '';

      enabledUsers = lib.filterAttrs (_: cfg: cfg.enable) config.hjem.users;
      userNames = lib.attrNames enabledUsers;
    in
    {
      options = {
        # Hjem's NixOS module sets this; system-manager does not define it.
        system.extraDependencies = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
        };

        # Referenced by Hjem even when the tmpfiles linker is not used.
        systemd.user.tmpfiles = lib.mkOption {
          type = lib.types.raw;
          default = {};
        };
      };

      config = {
        # Hjem's NixOS module expects an external linker that speaks the
        # positional "activate" / "diff" protocol. Wrap the hjem CLI so it
        # accepts that protocol and forwards to `hjem internal activate`.
        hjem.linker = lib.mkForce hjemLinker;

        # system-manager cannot reload bare template units (it needs an
        # instance like hjem-activate@myuser). Suppress the cosmetic reload
        # errors by telling system-manager not to restart them directly.
        systemd.services."hjem-activate@".serviceConfig.X-RestartIfChanged = "false";
        systemd.services."hjem-reload@".serviceConfig.X-RestartIfChanged = "false";
        systemd.services."hjem-update-state@".serviceConfig.X-RestartIfChanged = "false";

        # Stop hjem.target from being auto-started by system-manager.target;
        # we drive the per-user hjem units explicitly below to ensure they run
        # on every switch.
        systemd.targets.hjem.wantedBy = lib.mkForce [];

        # Explicit, non-template trigger service that starts the hjem template
        # instances for every enabled user on every system-manager activation.
        # It references the hjem-activate script so its store path changes
        # whenever the hjem manifest changes, forcing system-manager to restart
        # this trigger.
        systemd.services.hjem-apply = {
          description = "Apply Hjem configuration";
          serviceConfig.Type = "oneshot";
          script = lib.concatStringsSep "\n" (
            [ "# pinned to hjem generation: ${config.systemd.services."hjem-activate@".serviceConfig.ExecStart}" ]
            ++ lib.concatMap (user: [
              "${config.systemd.package}/bin/systemctl start hjem-activate@${user}.service"
              "${config.systemd.package}/bin/systemctl start hjem-reload@${user}.service"
              "${config.systemd.package}/bin/systemctl start hjem-update-state@${user}.service"
            ]) userNames
          );
          wantedBy = [ "system-manager.target" ];
        };
      };
    };
}
