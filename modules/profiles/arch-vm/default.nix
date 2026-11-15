{ inputs, self, ... }:
{
  flake.systemConfigs.arch-vm = inputs.system-manager.lib.makeSystemConfig {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.hjem.nixosModules.default
      self.modules.system-manager.arch-vm-base
      self.modules.system-manager.hjem-system-manager
      self.modules.system-manager.myuser
    ];
  };
}
