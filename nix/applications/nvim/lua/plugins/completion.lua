return {
	{
		name = "nvim-cmp",
		dir = "@nvim_cmp@",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = {
			{ name = "cmp-buffer", dir = "@cmp_buffer@" },
			{ name = "cmp-nvim-lsp", dir = "@cmp_nvim_lsp@" },
			{ name = "cmp-path", dir = "@cmp_path@" },
			{
				name = "cmp_luasnip",
				dir = "@cmp_luasnip@",
				dependencies = { name = "LuaSnip", dir = "@luasnip@" },
			},
			{ name = "cmp-cmdline", dir = "@cmp_cmdline@" },
			{ name = "lspkind.nvim", dir = "@lspkind_nvim@" },
			{ name = "copilot-cmp", dir = "@copilot_cmp@", config = true },
		},
		opts = function()
			vim.g.completeopt = "menu,menuone,noselect"
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local lspkind = require("lspkind")
			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				sources = cmp.config.sources({
					{ name = "copilot" },
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
					{ name = "buffer" },
				}),
				mapping = cmp.mapping.preset.insert({
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-l>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				}),
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				formatting = {
					format = lspkind.cmp_format({}),
				},
			})
			cmp.setup.cmdline("/", {
				mapping = cmp.mapping.preset.cmdline(),
				source = {
					{ name = "buffer" },
				},
			})
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),
			})
		end,
	},
	{
		name = "copilot.lua",
		dir = "@copilot_lua@",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = { enabled = false },
				panel = { enabled = false },
				filetypes = { markdown = true },
			})
		end,
	},
}
