return {
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    config = function()
      vim.api.nvim_set_keymap("n", "<F5>", ":DapContinue<CR>", { silent = true })
      vim.api.nvim_set_keymap("n", "<F10>", ":DapStepOver<CR>", { silent = true })
      vim.api.nvim_set_keymap("n", "<F11>", ":DapStepInto<CR>", { silent = true })
      vim.api.nvim_set_keymap("n", "<F12>", ":DapStepOut<CR>", { silent = true })
      vim.api.nvim_set_keymap("n", "<leader>b", ":DapToggleBreakpoint<CR>", { silent = true })
      vim.api.nvim_set_keymap(
        "n",
        "<leader>B",
        ':lua require("dap").set_breakpoint(nil, nil, vim.fn.input("Breakpoint condition: "))<CR>',
        { silent = true }
      )
      vim.api.nvim_set_keymap(
        "n",
        "<leader>lp",
        ':lua require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))<CR>',
        { silent = true }
      )
      vim.api.nvim_set_keymap("n", "<leader>dr", ':lua require("dap").repl.open()<CR>', { silent = true })
      vim.api.nvim_set_keymap("n", "<leader>dl", ':lua require("dap").run_last()<CR>', { silent = true })
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    event = "VeryLazy",
    config = function()
      require("dapui").setup()
      local dap, dapui = require("dap"), require("dapui")
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-treesitter/nvim-treesitter",
    },
    event = "VeryLazy",
    config = function()
      require("nvim-dap-virtual-text").setup()
    end,
  },
  {
    "mfussenegger/nvim-dap-python",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-treesitter/nvim-treesitter",
    },
    ft = "python",
    config = function()
      local dap_python = require("dap-python")
      dap_python.setup("python")
      dap_python.test_runner = "pytest"
      vim.api.nvim_set_keymap("n", "<Leader>dn", ':lua require("dap-python").test_method()<CR>', {silent = true})
      vim.api.nvim_set_keymap("n", "<Leader>df", ':lua require("dap-python").test_class()<CR>', {silent = true})
      vim.api.nvim_set_keymap("n", "<Leader>ds", '<Esc>:lua require("dap-python").debug_selection()<CR>', {silent = true})
    end,
  },
}
