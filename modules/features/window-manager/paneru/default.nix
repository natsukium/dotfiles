{ ... }:
{
  flake.modules.homeManager.paneru =
    {
      config,
      lib,
      inputs,
      pkgs,
      ...
    }:
    let
      appIdentity = pkgs.callPackage inputs.nix-mac-app-identity { };

      # A launchd agent runs a bare executable, which macOS identifies by
      # absolute path; in the store that path moves on every rebuild, taking
      # the Accessibility grant the window manager needs with it.
      app = appIdentity.mkAppBundle {
        package = config.services.paneru.finalPackage;
        identifier = "com.github.karinushka.paneru";
        # finalPackage is a symlinkJoin, so its name and version describe the
        # wrapper rather than paneru.
        name = "paneru";
        inherit (config.services.paneru.package) version;
      };
    in
    {
      options.my.programs.paneru.enable = lib.mkEnableOption "paneru";

      config = lib.mkIf config.my.programs.paneru.enable {
        launchd.agents.paneru.config.Program = lib.mkForce (lib.getExe app);

        services.paneru = {
          enable = true;

          package =
            inputs.paneru.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
              (oldAttrs: {
                # Emacs child frames report as AXWindow/AXFloatingWindow, so paneru tiles
                # the Corfu popup alongside its parent frame and collapses it. The patch
                # rejects windows that have a parent at the WindowServer level.
                patches = (oldAttrs.patches or [ ]) ++ [ ./emacs-child-frame.patch ];
              });

          settings = {
            options = {
              focus_follows_mouse = true;
              mouse_follows_focus = true;
              preset_column_widths = [
                0.33
                0.50
                0.66
              ];
            };

            windows.default = {
              title = ".*";
              horizontal_padding = 5;
              vertical_padding = 5;
            };

            swipe.gesture = {
              fingers_count = 3;
              direction = "Natural";
            };

            bindings = {
              window_focus_west = "cmd - h";
              window_focus_east = "cmd - l";
              window_focus_north = "cmd - k";
              window_focus_south = "cmd - j";

              window_swap_west = "cmd + ctrl - h";
              window_swap_east = "cmd + ctrl - l";
              window_swap_north = "cmd + ctrl - k";
              window_swap_south = "cmd + ctrl - j";

              window_center = "alt - c";
              window_fullwidth = "alt - f";
              window_resize = "alt - r";
              window_shrink = "alt + shift - r";

              window_stack = "alt + cmd - i";
              window_unstack = "alt + cmd - o";

              window_manage = "alt + cmd + shift - escape";
            };
          };
        };
      };
    };
}
