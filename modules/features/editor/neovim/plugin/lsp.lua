local pack = require("pack")

pack.on_event({ "BufReadPre", "BufNewFile" }, function()
	pack.add("none-ls.nvim", function()
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
	end)
end)

pack.on_event("BufRead", function()
	pack.add("lspsaga.nvim", function()
		require("lspsaga").setup({
			lightbulb = {
				sign = false,
			},
		})
	end)
end)

pack.on_ft({ "json", "jsonc", "json5" }, function()
	pack.add("SchemaStore.nvim")
end)

pack.add("rustaceanvim", function()
	vim.g.rustaceanvim = {
		server = {
			default_settings = {
				["rust-analyzer"] = { files = { excludeDirs = { "./.direnv" } } },
			},
		},
	}
end)
