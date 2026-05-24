return {
	{
		"blink.cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		before = function()
			require("lz.n").trigger_load("copilot.lua")
			require("lz.n").trigger_load("blink-cmp-copilot")
		end,
		after = function()
			require("blink.cmp").setup({
				completion = {
					menu = {
						draw = {
							columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
							treesitter = { "lsp" },
						},
					},
					documentation = {
						auto_show = true,
						auto_show_delay_ms = 500,
						treesitter_highlighting = true,
					},
				},
				signature = { enabled = true },
				sources = {
					default = { "lsp", "path", "snippets", "buffer", "copilot" },
					providers = {
						copilot = {
							name = "copilot",
							module = "blink-cmp-copilot",
							score_offset = 100,
							async = true,
						},
					},
				},
			})
		end,
	},
	{
		"copilot.lua",
		after = function()
			require("copilot").setup({
				suggestion = { enabled = false },
				panel = { enabled = false },
				filetypes = { markdown = true },
			})
		end,
	},
	{
		"blink-cmp-copilot",
	},
}
