{
  inputs,
  pkgs,
  ...
}:
let
  miniflux-port =
    inputs.self.outputs.nixosConfigurations.manyara.config.services.miniflux.config.PORT;
in
{
  programs.newsboat = {
    enable = if pkgs.stdenv.hostPlatform.isDarwin then false else true;
    autoReload = true;
    extraConfig = ''
      urls-source "miniflux"
      miniflux-url "http://manyara:${miniflux-port}"
      miniflux-login "natsukium"
      miniflux-passwordeval "rbw get miniflux"
      reload-threads 8

      bind-key j next
      bind-key k prev
    '';
  };
}
