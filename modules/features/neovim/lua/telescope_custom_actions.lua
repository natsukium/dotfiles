local action_utils = require("telescope.actions.utils")
local from_entry = require("telescope.from_entry")
local actions = require("telescope.actions")

local M = {}

local function extract_file_paths(prompt_bufnr)
	local paths = {}
	local seen = {}

	action_utils.map_entries(prompt_bufnr, function(entry, _, _)
		local path = from_entry.path(entry, false, false)
		if path and not seen[path] then
			table.insert(paths, path)
			seen[path] = true
		end
	end)

	return paths
end

M.grep_in_picker_results = function(prompt_bufnr)
	local paths = extract_file_paths(prompt_bufnr)

	if #paths == 0 then
		vim.notify("No valid file paths in picker results", vim.log.levels.WARN)
		return
	end

	actions.close(prompt_bufnr)

	require("telescope.builtin").live_grep({
		search_dirs = paths,
		prompt_title = string.format("Grep in %d file(s)", #paths),
	})
end

return M
