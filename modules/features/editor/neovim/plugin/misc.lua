local pack = require("pack")

local function trouble()
	pack.add("trouble.nvim", function()
		require("trouble").setup()
	end)
end

pack.on_cmd({ "Neotree" }, function()
	vim.g.neo_tree_remove_legacy_commands = 1
	pack.add("neo-tree.nvim", function()
		require("neo-tree").setup()
	end)
end)

local function telescope()
	pack.add("telescope.nvim", function()
		local telescope_ = require("telescope")
		local builtin = require("telescope.builtin")
		local custom_actions = require("telescope_custom_actions")

		vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
		vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
		vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
		vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})

		trouble()
		local open_with_trouble = require("trouble.sources.telescope").open
		telescope_.setup({
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
	end)
end

pack.on_cmd({ "Telescope" }, telescope)
pack.on_key({ "<leader>f" }, telescope)

pack.on_key({
	{ "f", mode = { "n", "x", "o" }, desc = "f" },
	{ "t", mode = { "n", "x", "o" }, desc = "t" },
}, function()
	pack.add("flit.nvim", function()
		require("flit").setup({ labeled_modes = "nx" })
	end)
end)

pack.on_key({
	{ "s", mode = { "n", "x", "o" }, desc = "Leap forward to" },
	{ "S", mode = { "n", "x", "o" }, desc = "Leap backward to" },
	{ "gs", mode = { "n", "x", "o" }, desc = "Leap from windows" },
}, function()
	pack.add("leap.nvim", function()
		require("leap").add_default_mappings(true)
		vim.keymap.del({ "x", "o" }, "x")
		vim.keymap.del({ "x", "o" }, "X")
	end)
end)

pack.later(function()
	pack.add("rainbow-delimiters.nvim")

	pack.add("nvim-surround", function()
		require("nvim-surround").setup()
	end)

	trouble()

	pack.add("which-key.nvim", function()
		vim.o.timeout = true
		vim.o.timeoutlen = 300
		require("which-key").setup({})
	end)

	pack.add("indent-blankline.nvim", function()
		require("ibl").setup()
	end)

	pack.add("vim-illuminate")
end)

pack.on_event("BufRead", function()
	pack.add("todo-comments.nvim", function()
		require("todo-comments").setup()
	end)

	pack.add("comment.nvim", function()
		require("Comment").setup()
	end)
end)

pack.on_cmd({ "OverseerRun", "OverseerToggle" }, function()
	pack.add("overseer.nvim", function()
		require("overseer").setup()
	end)
end)

local function markdown_preview()
	pack.add("markdown-preview.nvim", function()
		vim.g.mkdp_filetypes = { "markdown" }
		vim.keymap.set("n", "<leader>mp", ":MarkdownPreviewToggle<CR>")
	end)
end

pack.on_ft("markdown", markdown_preview)
pack.on_key({ "<Leader>mp" }, markdown_preview)

pack.on_cmd({ "Neogen" }, function()
	pack.add("neogen", function()
		require("neogen").setup({
			enable = true,
			languages = {
				python = { template = { annotation_convention = "google_docstrings" } },
			},
		})
	end)
end)

pack.on_event("InsertEnter", function()
	pack.add("nvim-autopairs", function()
		require("nvim-autopairs").setup({})
	end)
end)

pack.on_event("Syntax", function()
	pack.add("oil.nvim", function()
		require("oil").setup({
			skip_confirm_for_simple_edits = true,
			view_options = {
				show_hidden = true,
			},
		})
		vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
	end)
end)

pack.on_ft("markdown", function()
	pack.add("vim-table-mode")
end)

pack.on_key({ "<leader>j", "<leader>k" }, function()
	pack.add("vim-edgemotion", function()
		vim.keymap.set("n", "<leader>j", "<Plug>(edgemotion-j)")
		vim.keymap.set("n", "<leader>k", "<Plug>(edgemotion-k)")
	end)
end)

pack.add("snacks.nvim", function()
	require("snacks").setup({
		lazygit = {},
		bigfile = { size = 500 * 1024 },
	})
	vim.keymap.set("n", "<Space>gg", function()
		Snacks.lazygit.open()
	end)
end)
