{ vimPlugins }:
let
  pluginsWithLazy =
    bool:
    map (p: {
      plugin = p;
      optional = bool;
    });
in
with vimPlugins;
pluginsWithLazy true [
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
  nvim-treesitter.withAllGrammars
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
++ (pluginsWithLazy false [
  lz-n
  nvim-lspconfig
  nvim-web-devicons
  rustaceanvim
  snacks-nvim
])
