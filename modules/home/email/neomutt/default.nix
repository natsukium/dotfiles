{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.my.programs.neomutt;
in
{
  options.my.programs.neomutt = {
    enableHtmlView = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.programs.neomutt.enable (mkMerge [
    (mkIf cfg.enableHtmlView {
      programs.neomutt.extraConfig = ''
        set mailcap_path=${config.xdg.configHome}/neomutt/mailcap
        auto_view text/html
      '';

      xdg.configFile."neomutt/mailcap".text = ''
        text/html; w3m -I %{charset} -T text/html; copiousoutput;
      '';

      home.packages = [ pkgs.w3m ];
    })
  ]);
}
