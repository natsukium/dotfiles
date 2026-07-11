vim.lsp.enable({
	"astro",
	"bashls",
	"biome",
	"buf_ls",
	"docker_compose_language_service",
	"dockerls",
	"jsonls",
	"lua_ls",
	"nixd",
	"basedpyright",
	"rubocop",
	"ruff",
	-- "solargraph",
	"taplo",
	"terraformls",
	"tinymist",
	"ts_ls",
	"typos_lsp",
	"yamlls",
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)
		local opts = { buffer = args.buf }
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
		vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
		vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
		vim.keymap.set("n", "<space>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, opts)
		vim.keymap.set("n", "<leader>cf", function()
			vim.lsp.buf.format({ async = true })
		end, opts)
	end,
})
