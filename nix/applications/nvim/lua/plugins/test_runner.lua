return {
  {
    name = "neotest",
    dir = "@neotest@",
    dependencies = {
      --https://github.com/antoinemadec/FixCursorHold.nvim/issues/13
      { name = "FixCursorHold.nvim", dir = "@fixcursorhold_nvim@" },
      { "nvim-treesitter/nvim-treesitter" },
      { name = "plenary.nvim",       dir = "@plenary_nvim@" },
    },
    keys = { "<Leader>u" },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            dap = { justMyCode = false },
            python = "python",
          }),
        },
      })
      vim.keymap.set("n", "<Leader>ur", ':lua require("neotest").run.run()<CR>')
      vim.keymap.set("n", "<Leader>uf", ':lua require("neotest").run.run(vim.fn.expand("%"))<CR>')
      vim.keymap.set("n", "<Leader>ud", ':lua require("neotest").run.run({strategy = "dap"})<CR>')
      vim.keymap.set("n", "<Leader>us", ':lua require("neotest").run.stop()<CR>')
      vim.keymap.set("n", "<Leader>ua", ':lua require("neotest").run.attach()<CR>')
    end,
  },
  {
    name = "neotest-python",
    dir = "@neotest_python@",
    dependencies = {
      { name = "neotest",         dir = "@neotest@" },
      { "nvim-treesitter/nvim-treesitter" },
    },
  },
}
