{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.niri-flake.nixosModules.niri ];

  programs.niri.enable = true;

  programs.hyprland = {
    enable = true;
  };
  fonts.packages = with pkgs; [
    noto-fonts-cjk
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
    package = pkgs.greetd.tuigreet;
    settings = {
      default_session = {
        command = "${pkgs.lib.getExe pkgs.greetd.tuigreet} --time --remember --remember-session --cmd Hyprland";
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
