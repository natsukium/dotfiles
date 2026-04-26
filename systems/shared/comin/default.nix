{
  imports = [ ./alloy.nix ];

  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/natsukium/dotfiles";
      }
    ];
  };
}
