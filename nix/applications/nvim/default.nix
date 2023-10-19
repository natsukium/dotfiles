{
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs.inputs) nur;
  nurpkgs =
    (import nur {
      inherit pkgs;
      nurpkgs = pkgs;
    })
    .repos
    .natsukium;
  buildInputs = with pkgs; [
    gcc # for build treesitter parser
    nodejs_18
  ];
  lsp = with pkgs; [
    # astro
    nodePackages."@astrojs/language-server"
    # bash
    nodePackages.bash-language-server
    shellcheck
    shfmt
    # docker
    nodePackages.dockerfile-language-server-nodejs
    # hadolint
    docker-compose-language-service
    # lua
    lua-language-server
    stylua
    # nix
    alejandra
    nil
    # python
    black
    nodePackages.pyright
    ruff
    # terraform
    terraform-ls
  ];
  plugins = import ./plugins.nix {inherit pkgs nurpkgs;};
  ftdetectAstro = ''
    vim.filetype.add({
      extension = {
        astro = "astro"
      }
    })
  '';
  configFile = file: {"nvim/${file}".source = pkgs.substituteAll ({src = ./. + "/${file}";} // plugins);};
  configFiles = files: builtins.foldl' (x: y: x // y) {} (map configFile files);
in {
  programs.neovim = {
    enable = true;
    vimAlias = true;
    defaultEditor = true;
    extraPackages = buildInputs ++ lsp ++ pkgs.lib.attrValues plugins;
  };
  xdg.configFile =
    {
      "nvim/ftdetect/astro.lua".text = ftdetectAstro;
    }
    // configFiles [
      "./init.lua"
      "./lua/plugins/completion.lua"
      "./lua/plugins/dap.lua"
      "./lua/plugins/lsp.lua"
      "./lua/plugins/misc.lua"
      "./lua/plugins/test_runner.lua"
      "./lua/plugins/ui.lua"
    ];
}
