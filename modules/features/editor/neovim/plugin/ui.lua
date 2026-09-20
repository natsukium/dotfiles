local pack = require("pack")

pack.later(function()
	pack.add("lualine.nvim", function()
		require("lualine").setup({
			options = {
				theme = "nord",
				globalstatus = true,
			},
		})
	end)

	pack.add("bufferline.nvim", function()
		local highlights = require("nord").bufferline.highlights({
			italic = true,
			bold = true,
		})

		require("bufferline").setup({
			options = {
				separator_style = "thin",
			},
			highlights = highlights,
		})
	end)

	pack.add("noice.nvim", function()
		require("noice").setup({
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
		})
	end)

	pack.add("dressing.nvim")
end)
