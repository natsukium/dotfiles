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
            {
              externalDiffCommand = "difft --color=always";
            }
          ];
        };
      };
    };
  };

  programs.difftastic = {
    enable = true;
  };
}
