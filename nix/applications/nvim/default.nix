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
  lazynvimInit = ''
    local M = {}

    function M.setup()
      local lazypath = "${pkgs.vimPlugins.lazy-nvim}"
      vim.opt.rtp:prepend(lazypath)
    end

    return M
  '';
  ftdetectAstro = ''
    vim.filetype.add({
      extension = {
        astro = "astro"
      }
    })
  '';
  plugins-completion = pkgs.substituteAll ({src = ./config/lua/plugins/completion.lua;} // plugins);
  plugins-dap = pkgs.substituteAll ({src = ./config/lua/plugins/dap.lua;} // plugins);
  plugins-lsp = pkgs.substituteAll ({src = ./config/lua/plugins/lsp.lua;} // plugins);
  plugins-misc = pkgs.substituteAll ({src = ./config/lua/plugins/misc.lua;} // plugins);
  plugins-test-runner = pkgs.substituteAll ({src = ./config/lua/plugins/test_runner.lua;} // plugins);
  plugins-ui = pkgs.substituteAll ({src = ./config/lua/plugins/ui.lua;} // plugins);
in {
  programs.neovim = {
    enable = true;
    vimAlias = true;
    defaultEditor = true;
    extraPackages = buildInputs ++ lsp ++ pkgs.lib.attrValues plugins;
  };
  xdg.configFile."nvim/init.lua".source = ./config/init.lua;
  xdg.configFile."nvim/lua/plugins/completion.lua".source = plugins-completion;
  xdg.configFile."nvim/lua/plugins/dap.lua".source = plugins-dap;
  xdg.configFile."nvim/lua/plugins/lsp.lua".source = plugins-lsp;
  xdg.configFile."nvim/lua/plugins/misc.lua".source = plugins-misc;
  xdg.configFile."nvim/lua/plugins/test_runner.lua".source = plugins-test-runner;
  xdg.configFile."nvim/lua/plugins/ui.lua".source = plugins-ui;
  xdg.configFile."nvim/lua/lazynvim-init.lua".text = lazynvimInit;
  xdg.configFile."nvim/ftdetect/astro.lua".text = ftdetectAstro;
}
