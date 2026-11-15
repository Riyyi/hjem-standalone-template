{ lib, ... }:
{
  flake.modules.system-manager.myuser = {
    users.users.myuser = {
      enable = true;
      name = "myuser";
      home = "/home/myuser";
      isNormalUser = true;
    };

    hjem.users.myuser = {
      enable = true;
      clobberFiles = true;

      files = {
        ".bashrc".text = ''
          # managed by hjem

          # If not running interactively, don't do anything
          [[ $- != *i* ]] && return

          export EDITOR=nvim

          alias ls='ls --color=auto'
          alias la='ls -lAGh --color=auto'
          alias grep='grep --color=auto'
          PS1='[\u@\h \W]\$ '
        '';

        ".config/test-dotfiles/README".text = ''
          Hello from hjem on arch-vm!
        '';
      };

      xdg.config.files."test-dotfiles/config.json" = {
        generator = lib.generators.toJSON { };
        value = {
          managed-by = "hjem";
          host = "arch-vm";
        };
      };
    };
  };
}
