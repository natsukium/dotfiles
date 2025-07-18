{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.niri = {
    enable = true;
  };

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  programs.hyprland = {
    # fcitx doesn't start if multiple WMs are enabled
    # TODO: fix ime settings
    enable = false;
  };
  fonts.packages = with pkgs; [
    moralerspace-hwnf
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liga-hackgen-nf-font
  ];

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.lib.getExe pkgs.greetd.tuigreet} --time --remember --remember-session --cmd niri-session";
        user = "greeter";
      };
    };
  };

  # suppress systemd error message on tuigreet
  # https://github.com/apognu/tuigreet/issues/68#issuecomment-1586359960
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInputs = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  services.gnome.gnome-keyring.enable = true;

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = [ pkgs.fcitx5-mozc ];
      waylandFrontend = true;
    };
  };

  environment.variables = lib.optionalAttrs config.i18n.inputMethod.enable {
    "GLFW_IM_MODULE" = "ibus";
  };
}
