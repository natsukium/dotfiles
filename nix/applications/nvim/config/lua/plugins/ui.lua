return {
	{
		"nvim-lualine/lualine.nvim",
		config = function()
			require("lualine").setup({ options = { theme = "nord" } })
		end,
		event = "VeryLazy",
	},
	{
		"akinsho/bufferline.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
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
		event = "VeryLazy",
	},
	{
		"folke/noice.nvim",
    event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		config = function()
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
		"stevearc/dressing.nvim",
		event = "VeryLazy",
	},
}
