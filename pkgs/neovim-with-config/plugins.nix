{ vimPlugins }:
let
  toLazyPlugins = map (plugin: {
    inherit plugin;
    optional = true;
  });
  toEagerPlugins = map (plugin: {
    inherit plugin;
    optional = false;
  });
in
with vimPlugins;
toLazyPlugins [
  FixCursorHold-nvim
  SchemaStore-nvim
  blink-cmp
  blink-cmp-copilot
  bufferline-nvim
  comment-nvim
  copilot-lua
  CopilotChat-nvim
  diffview-nvim
  dressing-nvim
  flit-nvim
  gitlinker-nvim
  gitsigns-nvim
  indent-blankline-nvim
  leap-nvim
  lspsaga-nvim
  lualine-nvim
  luasnip
  markdown-preview-nvim
  neo-tree-nvim
  neogen
  neotest
  neotest-python
  noice-nvim
  none-ls-nvim
  nord-nvim
  nvim-autopairs
  nvim-dap
  nvim-dap-python
  nvim-dap-ui
  nvim-dap-virtual-text
  nvim-nio
  nvim-notify
  nvim-surround
  octo-nvim
  oil-nvim
  overseer-nvim
  rainbow-delimiters-nvim
  telescope-nvim
  todo-comments-nvim
  trouble-nvim
  vim-edgemotion
  vim-illuminate
  vim-table-mode
  which-key-nvim
]
++ (toEagerPlugins [
  lz-n
  nvim-lspconfig
  # Eager load to make treesitter queries available in runtimepath for Telescope preview highlighting.
  nvim-treesitter.withAllGrammars
  nvim-web-devicons
  rustaceanvim
  snacks-nvim
])
