return {
	{
		"neotest",
		keys = { "<Leader>u" },
		after = function()
			require("neotest").setup({
				adapters = {
					require("neotest-python")({
						dap = { justMyCode = false },
						python = "python",
					}),
					require("rustaceanvim.neotest"),
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
		"neotest-python",
	},
}
