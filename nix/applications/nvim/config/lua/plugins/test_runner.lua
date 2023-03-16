return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"antoinemadec/FixCursorHold.nvim", --https://github.com/antoinemadec/FixCursorHold.nvim/issues/13
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
		"nvim-neotest/neotest-python",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-neotest/neotest",
		},
	},
}
