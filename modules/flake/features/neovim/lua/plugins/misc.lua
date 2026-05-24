return {
	{
		"nord.nvim",
		colorscheme = "nord",
		after = function()
			vim.g.nord_contrast = true
			vim.g.nord_italic = false
			require("nord").set()
		end,
	},
	{
		"neo-tree.nvim",
		cmd = { "Neotree" },
		before = function()
			vim.g.neo_tree_remove_legacy_commands = 1
		end,
		after = function()
			require("neo-tree").setup()
		end,
	},
	{
		"telescope.nvim",
		cmd = "Telescope",
		keys = { "<leader>f" },
		after = function()
			local telescope = require("telescope")
			local builtin = require("telescope.builtin")
			local custom_actions = require("telescope_custom_actions")

			vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
			vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})

			require("lz.n").trigger_load("trouble.nvim")
			local open_with_trouble = require("trouble.sources.telescope").open
			telescope.setup({
				defaults = {
					layout_strategy = "flex",
					mappings = {
						i = {
							["<c-t>"] = open_with_trouble,
							["<c-g>"] = custom_actions.grep_in_picker_results,
						},
						n = {
							["<c-t>"] = open_with_trouble,
							["<c-g>"] = custom_actions.grep_in_picker_results,
						},
					},
				},
			})
		end,
	},
	{
		"flit.nvim",
		keys = function()
			local ret = {}
			for _, key in ipairs({ "f", "f", "t", "t" }) do
				ret[#ret + 1] = { key, mode = { "n", "x", "o" }, desc = key }
			end
			return ret
		end,
		after = function()
			require("flit").setup({ labeled_modes = "nx" })
		end,
	},
	{
		"leap.nvim",
		keys = {
			{ "s", mode = { "n", "x", "o" }, desc = "Leap forward to" },
			{ "S", mode = { "n", "x", "o" }, desc = "Leap backward to" },
			{ "gs", mode = { "n", "x", "o" }, desc = "Leap from windows" },
		},
		after = function(_, opts)
			local leap = require("leap")
			for k, v in pairs(opts) do
				leap.opts[k] = v
			end
			leap.add_default_mappings(true)
			vim.keymap.del({ "x", "o" }, "x")
			vim.keymap.del({ "x", "o" }, "X")
		end,
	},
	{
		"nvim-treesitter",
		event = "BufRead",
	},
	{
		"rainbow-delimiters.nvim",
		event = "DeferredUIEnter",
	},
	{
		"nvim-surround",
		after = function()
			require("nvim-surround").setup()
		end,
		event = "DeferredUIEnter",
	},
	{
		"trouble.nvim",
		after = function()
			require("trouble").setup()
		end,
		event = "DeferredUIEnter",
	},
	{
		"which-key.nvim",
		after = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
			require("which-key").setup({})
		end,
		event = "DeferredUIEnter",
	},
	{
		"todo-comments.nvim",
		after = function()
			require("todo-comments").setup()
		end,
		event = "BufRead",
	},
	{
		"indent-blankline.nvim",
		event = "DeferredUIEnter",
		after = function()
			require("ibl").setup()
		end,
	},
	{
		"comment.nvim",
		event = "BufRead",
		after = function()
			require("Comment").setup()
		end,
	},
	{
		"vim-illuminate",
		event = "DeferredUIEnter",
	},
	{
		"overseer.nvim",
		cmd = { "OverseerRun", "OverseerToggle" },
		after = function()
			require("overseer").setup()
		end,
	},
	{
		"markdown-preview.nvim",
		ft = "markdown",
		keys = { "<Leader>mp" },
		after = function()
			vim.g.mkdp_filetypes = { "markdown" }
			vim.keymap.set("n", "<leader>mp", ":MarkdownPreviewToggle<CR>")
		end,
	},
	{
		"neogen",
		cmd = "Neogen",
		after = function()
			require("neogen").setup({
				enable = true,
				languages = {
					python = { template = { annotation_convention = "google_docstrings" } },
				},
			})
		end,
	},
	{
		"nvim-autopairs",
		event = "InsertEnter",
		after = function()
			local npairs = require("nvim-autopairs")
			local Rule = require("nvim-autopairs.rule")
			npairs.setup({})
		end,
	},
	{
		"oil.nvim",
		event = "syntax",
		after = function()
			require("oil").setup({
				skip_confirm_for_simple_edits = true,
				view_options = {
					show_hidden = true,
				},
			})
			vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
		end,
	},
	{
		"vim-table-mode",
		ft = "markdown",
	},
	{
		"vim-edgemotion",
		keys = { "<leader>j", "<leader>k" },
		after = function()
			vim.keymap.set("n", "<leader>j", "<Plug>(edgemotion-j)")
			vim.keymap.set("n", "<leader>k", "<Plug>(edgemotion-k)")
		end,
	},
	{
		"CopilotChat.nvim",
		after = function()
			require("CopilotChat").setup()
		end,
		event = "DeferredUIEnter",
	},
	{
		"snacks.nvim",
		after = function()
			require("snacks").setup({
				lazygit = {},
				bigfile = { size = 500 * 1024 },
			})
			vim.keymap.set("n", "<Space>gg", function()
				Snacks.lazygit.open()
			end)
		end,
	},
}
