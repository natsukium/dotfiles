{
  pkgs,
  nurpkgs,
}: let
  normalizedPluginAttr = p: {"${builtins.replaceStrings ["-" "."] ["_" "_"] (pkgs.lib.toLower p.pname)}" = p;};
  plugins = p: builtins.foldl' (x: y: x // y) {} (map normalizedPluginAttr p);
in
  with pkgs.vimPlugins;
  with nurpkgs.vimPlugins;
    plugins [
      ChatGPT-nvim
      FixCursorHold-nvim
      bufferline-nvim
      cmp-buffer
      cmp-cmdline
      cmp-nvim-lsp
      cmp-path
      cmp_luasnip
      comment-nvim
      copilot-cmp
      copilot-lua
      diffview-nvim
      dressing-nvim
      flit-nvim
      gitsigns-nvim
      indent-blankline-nvim
      lazy-nvim
      leap-nvim
      lspkind-nvim
      lspsaga-nvim
      lualine-nvim
      luasnip
      markdown-preview-nvim
      neo-tree-nvim
      neotest
      neotest-python
      noice-nvim
      none-ls-nvim
      nord-nvim
      nui-nvim
      nvim-autopairs
      nvim-cmp
      nvim-dap
      nvim-dap-python
      nvim-dap-ui
      nvim-dap-virtual-text
      nvim-lspconfig
      nvim-notify
      nvim-surround
      nvim-treesitter
      nvim-web-devicons
      octo-nvim
      overseer-nvim
      plenary-nvim
      rainbow-delimiters-nvim
      telescope-nvim
      todo-comments-nvim
      trouble-nvim
      vim-illuminate
      # vim-pydocstring
      which-key-nvim
    ]
