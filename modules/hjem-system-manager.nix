{
  flake.modules.system-manager.hjem-system-manager = { lib, config, ... }:
    let
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
