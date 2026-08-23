return {
	{
		"lualine.nvim",
		after = function()
			require("lualine").setup({
				options = {
					theme = "nord",
					globalstatus = true,
				},
			})
		end,
		event = "DeferredUIEnter",
	},
	{
		"bufferline.nvim",
		after = function()
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
		end,
		event = "DeferredUIEnter",
	},
	{
		"noice.nvim",
		event = "DeferredUIEnter",
		after = function()
			require("noice").setup({
				lsp = {
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
						["cmp.entry.get_documentation"] = true,
					},
				},
			})
		end,
	},
	{
		"dressing.nvim",
		event = "DeferredUIEnter",
	},
}
