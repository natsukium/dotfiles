{ pkgs, ... }:
{
  programs.waybar = {
    enable = true;
    style = ''
      * {
        font-family: "Liga HackGen35 Console NF";
        font-size: 14px;
      }

      window#waybar {
        background: transparent;
      }

      #clock {
        background: @base01;
        border: 2px solid @base03;
        border-radius: 5px;
      }

      #cpu {
        background: @base01;
        border: 2px solid @base03;
        border-radius: 5px;
      }

      #memory {
        background: @base01;
        border: 2px solid @base03;
        border-radius: 5px;
      }
    '';
    settings = {
      mainBar = {
        position = "left";
        width = 30;
        margin-top = 10;
        margin-bottom = 10;
        margin-left = 10;
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "hyprland/window" ];
        modules-right = [
          "clock"
          "cpu"
          "memory"
        ];
        "hyprland/workspaces" = { };
        clock = {
          format = ''
            {:%H
            %M
            %b
            %e}
          '';
          tooltip = true;
          tooltip-format = "{:%Y.%m.%d %H:%M}";
          interval = 5;
        };
        cpu = {
          interval = 5;
          format = ''
            
            {usage}%
          '';
          states = {
            warning = 70;
            critical = 90;
          };
        };
        memory = {
          interval = 5;
          format = ''
            
            {}%
          '';
          states = {
            warning = 70;
            critical = 90;
          };
        };
      };
    };
  };
}
