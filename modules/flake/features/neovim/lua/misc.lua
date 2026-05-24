-- https://blog.atusy.net/2023/12/09/gf-open-url/
vim.keymap.set("n", "gf", function()
	local cfile = vim.fn.expand("<cfile>")
	if cfile:match("^https?://") then
		vim.ui.open(cfile)
	else
		vim.cmd("normal! gF")
	end
end)
