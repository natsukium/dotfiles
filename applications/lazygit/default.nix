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
