{
  config,
  pkgs,
  ...
}:
let
  nurpkgs = config.nur.repos.natsukium;
in
{
  programs.hyprland = {
    enable = true;
  };
  fonts.packages = with pkgs; [
    noto-fonts-cjk
    noto-fonts-emoji
    nurpkgs.liga-hackgen-nf-font
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
}
