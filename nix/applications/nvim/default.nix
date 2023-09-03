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
  plugins = with pkgs.vimPlugins; [
    lazy-nvim
    markdown-preview-nvim
    nurpkgs.vimPlugins.vim-pydocstring
  ];
  lazynvimInit = ''
    local M = {}

    function M.setup()
      local lazypath = "${pkgs.vimPlugins.lazy-nvim}"
      vim.opt.rtp:prepend(lazypath)
    end

    return M
  '';
  markdownPreviewNvim = ''
    return {
      {
        dir = "${pkgs.vimPlugins.markdown-preview-nvim}",
        ft = "markdown",
        keys = { "<Leader>mp" },
        config = function()
          vim.g.mkdp_filetypes = { "markdown" }
          vim.keymap.set("n", "<leader>mp", ":MarkdownPreviewToggle<CR>")
        end,
      },
    }
  '';
  vimPydocstring = ''
    return {
      {
        dir = "${nurpkgs.vimPlugins.vim-pydocstring}",
        ft = "python",
        config = function()
          vim.g.pydocstring_formatter = "google"
        end,
      },
    }
  '';
  ftdetectAstro = ''
    vim.filetype.add({
      extension = {
        astro = "astro"
      }
    })
  '';
in {
  programs.neovim = {
    enable = true;
    vimAlias = true;
    defaultEditor = true;
    extraPackages = buildInputs ++ lsp ++ plugins;
  };
  home.file."./.config/nvim/" = {
    source = ./config;
    recursive = true;
  };
  xdg.configFile."nvim/lua/lazynvim-init.lua".text = lazynvimInit;
  xdg.configFile."nvim/lua/plugins/markdown-preview-nvim.lua".text = markdownPreviewNvim;
  xdg.configFile."nvim/lua/plugins/vim-pydocstring.lua".text = vimPydocstring;
  xdg.configFile."nvim/ftdetect/astro.lua".text = ftdetectAstro;
}
