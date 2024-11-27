return {
	{
		name = "nord.nvim",
		dir = "@nord_nvim@",
		config = function()
			vim.g.nord_contrast = true
			vim.g.nord_italic = false
			require("nord").set()
		end,
		lazy = false,
	},
	{
		name = "neo-tree.nvim",
		dir = "@neo_tree_nvim@",
		dependencies = {
			{ name = "nui.nvim", dir = "@nui_nvim@" },
			{ name = "nvim-web-devicons", dir = "@nvim_web_devicons@" },
			{ name = "plenary.nvim", dir = "@plenary_nvim@" },
		},
		cmd = { "Neotree" },
		init = function()
			vim.g.neo_tree_remove_legacy_commands = 1
		end,
		config = true,
	},
	{
		name = "telescope.nvim",
		dir = "@telescope_nvim@",
		dependencies = { name = "plenary.nvim", dir = "@plenary_nvim@" },
		cmd = "Telescope",
		keys = { "<leader>f" },
		config = function()
			local telescope = require("telescope")
			local open_with_trouble = require("trouble.sources.telescope").open
			local builtin = require("telescope.builtin")

			vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
			vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})

			telescope.setup({
				defaults = {
					layout_strategy = "flex",
					mappings = {
						i = { ["<c-t>"] = open_with_trouble },
						n = { ["<c-t>"] = open_with_trouble },
					},
				},
			})
		end,
	},
	{
		name = "flit.nvim",
		dir = "@flit_nvim@",
		keys = function()
			local ret = {}
			for _, key in ipairs({ "f", "f", "t", "t" }) do
				ret[#ret + 1] = { key, mode = { "n", "x", "o" }, desc = key }
			end
			return ret
		end,
		opts = { labeled_modes = "nx" },
	},
	{
		name = "leap.nvim",
		dir = "@leap_nvim@",
		keys = {
			{ "s", mode = { "n", "x", "o" }, desc = "Leap forward to" },
			{ "S", mode = { "n", "x", "o" }, desc = "Leap backward to" },
			{ "gs", mode = { "n", "x", "o" }, desc = "Leap from windows" },
		},
		config = function(_, opts)
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
		name = "nvim-treesitter",
		dir = "@nvim_treesitter@",
		config = function()
			vim.opt.runtimepath:append("@ts_parser_dirs@")
		end,
		event = "BufRead",
	},
	{
		name = "rainbow-delimiters.nvim",
		dir = "@rainbow_delimiters_nvim@",
		event = "VeryLazy",
	},
	{
		name = "nvim-surround",
		dir = "@nvim_surround@",
		config = true,
		event = "VeryLazy",
	},
	{
		name = "trouble.nvim",
		dir = "@trouble_nvim@",
		config = true,
		event = "VeryLazy",
	},
	{
		name = "which-key.nvim",
		dir = "@which_key_nvim@",
		config = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
			require("which-key").setup({})
		end,
		event = "VeryLazy",
	},
	{
		name = "todo-comments.nvim",
		dir = "@todo_comments_nvim@",
		config = true,
		event = "BufRead",
	},
	{
		name = "indent-blankline.nvim",
		dir = "@indent_blankline_nvim@",
		event = "VeryLazy",
		main = "ibl",
		config = true,
	},
	{
		name = "Comment.nvim",
		dir = "@comment_nvim@",
		event = "BufRead",
		config = true,
	},
	{
		name = "vim-illuminate",
		dir = "@vim_illuminate@",
		event = "VeryLazy",
	},
	{
		name = "overseer.nvim",
		dir = "@overseer_nvim@",
		cmd = { "OverseerRun", "OverseerToggle" },
		config = true,
	},
	{
		name = "ChatGPT.nvim",
		dir = "@chatgpt_nvim@",
		dependencies = {
			{ name = "nui.nvim", dir = "@nui_nvim@" },
			{ name = "plenary.nvim", dir = "@plenary_nvim@" },
			{ name = "telescope.nvim", dir = "@telescope_nvim@" },
		},
		cmd = {
			"ChatGPT",
			"ChatGPTActAs",
			"ChatGPTEditWithInstructions",
			"ChatGPTRun",
		},
		config = function()
			require("chatgpt").setup({
				openai_params = {
					model = "gpt-4o",
				},
				openai_edit_params = {
					model = "gpt-4o",
				},
				api_key_cmd = "rbw get OPENAI_API_KEY",
			})
		end,
	},
	{
		name = "markdown-preview.nvim",
		dir = "@markdown_preview_nvim@",
		ft = "markdown",
		keys = { "<Leader>mp" },
		config = function()
			vim.g.mkdp_filetypes = { "markdown" }
			vim.keymap.set("n", "<leader>mp", ":MarkdownPreviewToggle<CR>")
		end,
	},
	{
		name = "neogen",
		dir = "@neogen@",
		cmd = "Neogen",
		config = function()
			require("neogen").setup({
				enable = true,
				languages = {
					python = { template = { annotation_convention = "google_docstrings" } },
				},
			})
		end,
	},
	{
		name = "nvim-autopairs",
		dir = "@nvim_autopairs@",
		event = "InsertEnter",
		config = function()
			local npairs = require("nvim-autopairs")
			local Rule = require("nvim-autopairs.rule")
			npairs.setup({})
		end,
	},
	{
		name = "oil.nvim",
		dir = "@oil_nvim@",
		event = "syntax",
		config = function()
			require("oil").setup({
				skip_confirm_for_simple_edits = true,
				view_options = {
					show_hidden = true,
				},
			})
		end,
	},
	{
		name = "vim-table-mode",
		dir = "@vim_table_mode@",
		ft = "markdown",
		config = true,
	},
	{
		name = "vim-edgemotion",
		dir = "@vim_edgemotion@",
		keys = { "<leader>j", "<leader>k" },
		config = function()
			vim.keymap.set("n", "<leader>j", "<Plug>(edgemotion-j)")
			vim.keymap.set("n", "<leader>k", "<Plug>(edgemotion-k)")
		end,
	},
	{
		name = "CopilotChat.nvim",
		dir = "@copilotchat_nvim@",
		dependencies = {
			{ name = "copilot.lua", dir = "@copilot_lua@" },
			{ name = "plenary.nvim", dir = "@plenary_nvim@" },
		},
		config = true,
		event = "VeryLazy",
	},
	{
		name = "vim-wakatime",
		dir = "@vim_wakatime@",
		event = "VeryLazy",
	},
}
