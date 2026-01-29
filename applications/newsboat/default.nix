{
  inputs,
  ...
}:
let
  miniflux-port =
    inputs.self.outputs.nixosConfigurations.manyara.config.services.miniflux.config.PORT;
in
{
  programs.newsboat = {
    enable = true;
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
