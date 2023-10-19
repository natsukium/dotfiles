vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.mouse = "a"

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wildmode = "longest:full,full"

vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.list = true
vim.opt.listchars:append("space:⋅")
vim.opt.completeopt = "menu,menuone,noselect"

vim.keymap.set("i", "jj", "<Esc>", { noremap = true })
vim.keymap.set("n", "x", '"_x', { noremap = true })
vim.keymap.set("n", "s", '"_s', { noremap = true })
vim.keymap.set("n", "<Leader>h", "^", { noremap = true })
vim.keymap.set("n", "<Leader>l", "$", { noremap = true })
vim.keymap.set("v", "<Leader>h", "^", { noremap = true })
vim.keymap.set("v", "<Leader>l", "$", { noremap = true })
vim.keymap.set("n", "<Leader>w", ":w<CR>")
vim.keymap.set("n", "<Esc><Esc>", ":nohlsearch<CR><Esc>")

local function float_term(cmd)
	local opts = { size = { width = 0.9, height = 0.9 } }
	require("lazy.util").float_term(cmd, opts)
end
vim.keymap.set("n", "<Leader>gg", function()
	float_term({ "gitui" })
end)

-- buffers
vim.keymap.set("n", "[b", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
vim.keymap.set("n", "]b", "<cmd>bnext<CR>", { desc = "Next buffer" })

-- window
vim.keymap.set("n", "<leader>ww", "<C-W>p", { desc = "Other window" })
vim.keymap.set("n", "<leader>wd", "<C-W>c", { desc = "Delete window" })
vim.keymap.set("n", "<leader>w-", "<C-W>s", { desc = "Split window below" })
vim.keymap.set("n", "<leader>w|", "<C-W>v", { desc = "Split window right" })
vim.keymap.set("n", "<leader>-", "<C-W>s", { desc = "Split window below" })
vim.keymap.set("n", "<leader>|", "<C-W>v", { desc = "Split window right" })

-- tabs
vim.keymap.set("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
vim.keymap.set("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
vim.keymap.set("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
vim.keymap.set("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
vim.keymap.set("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
vim.keymap.set("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

local lazypath = "@lazy_nvim@"
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	defaults = { lazy = true },
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
	spec = "plugins",
})
