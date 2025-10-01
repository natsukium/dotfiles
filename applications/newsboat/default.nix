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
    # broken on macos
    # https://github.com/newsboat/newsboat/pull/3185
    enable = pkgs.stdenv.hostPlatform.isLinux;
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
