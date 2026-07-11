return {
	{
		"none-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
		after = function()
			local null_ls = require("null-ls")
			null_ls.setup({
				sources = {
					null_ls.builtins.diagnostics.hadolint,
					null_ls.builtins.diagnostics.textlint,
					null_ls.builtins.formatting.shfmt,
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.formatting.textlint,
				},
			})
		end,
	},
	{
		"lspsaga.nvim",
		event = "BufRead",
		after = function()
			require("lspsaga").setup({
				lightbulb = {
					sign = false,
				},
			})
		end,
	},
	{
		"SchemaStore.nvim",
		ft = { "json", "jsonc", "json5" },
	},
	{
		"rustaceanvim",
		after = function()
			vim.g.rustaceanvim = {
				server = {
					default_settings = {
						["rust-analyzer"] = { files = { excludeDirs = { "./.direnv" } } },
					},
				},
			}
		end,
	},
}
