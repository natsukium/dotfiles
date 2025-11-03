{ pkgs, ... }:
{
  programs = {
    lazygit = {
      enable = true;
      settings = {
        gui = {
          showIcons = true;
        };
        git = {
          overrideGpg = true;
          pagers = [
            {
              colorArg = "always";
              pager = "delta --dark --paging=never";
            }
          ];
        };
      };
    };
  };
}
