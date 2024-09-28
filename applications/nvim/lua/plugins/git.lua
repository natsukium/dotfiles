return {
	{
		name = "diffview.nvim",
		dir = "@diffview_nvim@",
		dependencies = { { name = "plenary.nvim", dir = "@plenary_nvim@" } },
		config = true,
		event = "VeryLazy",
	},
	{
		name = "gitlinker.nvim",
		dir = "@gitlinker_nvim@",
		config = true,
		event = "VeryLazy",
	},
	{
		name = "gitsigns.nvim",
		dir = "@gitsigns_nvim@",
		config = function()
			require("gitsigns").setup({
				signcolumn = false,
				numhl = true,
				current_line_blame = true,
				on_attach = function(bufnr)
					local gs = package.loaded.gitsigns

					local function map(mode, l, r, opts)
						opts = opts or {}
						opts.buffer = bufnr
						vim.keymap.set(mode, l, r, opts)
					end

					-- Navigation
					map("n", "]c", function()
						if vim.wo.diff then
							return "]c"
						end
						vim.schedule(function()
							gs.next_hunk()
						end)
						return "<Ignore>"
					end, { expr = true })

					map("n", "[c", function()
						if vim.wo.diff then
							return "[c"
						end
						vim.schedule(function()
							gs.prev_hunk()
						end)
						return "<Ignore>"
					end, { expr = true })

					-- Actions
					map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>")
					map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>")
					map("n", "<leader>hS", gs.stage_buffer)
					map("n", "<leader>hu", gs.undo_stage_hunk)
					map("n", "<leader>hR", gs.reset_buffer)
					map("n", "<leader>hp", gs.preview_hunk)
					map("n", "<leader>hb", function()
						gs.blame_line({ full = true })
					end)
					map("n", "<leader>tb", gs.toggle_current_line_blame)
					map("n", "<leader>hd", gs.diffthis)
					map("n", "<leader>hD", function()
						gs.diffthis("~")
					end)
					map("n", "<leader>td", gs.toggle_deleted)

					-- Text object
					map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
				end,
			})
		end,
		event = "BufRead",
	},
	{
		name = "octo.nvim",
		dir = "@octo_nvim@",
		dependencies = {
			{ name = "plenary.nvim", dir = "@plenary_nvim@" },
			{ name = "telescope.nvim", dir = "@telescope_nvim@" },
			{ name = "nvim-web-devicons", dir = "@nvim_web_devicons@" },
		},
		cmd = { "Octo" },
		config = function()
			require("octo").setup({
				ssh_aliases = { ["github.com-emu"] = "github.com" },
			})
		end,
	},
}
