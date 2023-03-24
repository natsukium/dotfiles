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
  ];
  lsp = with pkgs; [
    # bash
    nodePackages.bash-language-server
    shellcheck
    shfmt
    # lua
    lua-language-server
    stylua
    # nix
    alejandra
    nil
    # python
    black
    nodePackages.pyright
  ];
  plugins = with pkgs.vimPlugins; [
    lazy-nvim
    markdown-preview-nvim
    nurpkgs.vimPlugins.vim-pydocstring
  ];
  lazynvimInit = pkgs.writeText "lazynvim-init.lua" ''
    local M = {}

    function M.setup()
      local lazypath = "${pkgs.vimPlugins.lazy-nvim}"
      vim.opt.rtp:prepend(lazypath)
    end

    return M
  '';
  markdownPreviewNvim = pkgs.writeText "markdown-preview-nvim.lua" ''
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
  vimPydocstring = pkgs.writeText "vim-pydocstring.lua" ''
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
  xdg.configFile."nvim/lua/lazynvim-init.lua".source = lazynvimInit;
  xdg.configFile."nvim/lua/plugins/markdown-preview-nvim.lua".source = markdownPreviewNvim;
  xdg.configFile."nvim/lua/plugins/vim-pydocstring.lua".source = vimPydocstring;
}
