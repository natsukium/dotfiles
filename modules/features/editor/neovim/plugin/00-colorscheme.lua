local pack = require("pack")

pack.add("nord.nvim", function()
	vim.g.nord_contrast = true
	vim.g.nord_italic = false
	require("nord").set()
end)
