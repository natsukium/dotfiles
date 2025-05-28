-- Nurl command
vim.api.nvim_create_user_command("Nurl", function(opts)
	local args = vim.split(opts.args, " ")
	if #args < 1 then
		vim.notify("Usage: :Nurl <url> [rev]", vim.log.levels.ERROR)
		return
	end

	local url = args[1]
	local rev = args[2]

	local cmd = { "nurl", url }
	if rev then
		table.insert(cmd, rev)
	end

	-- Store cursor position and buffer at command execution time
	local buf = vim.api.nvim_get_current_buf()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local current_line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
	local indent = current_line:match("^%s*") or ""

	-- Insert after cursor position (col + 1)
	col = col + 1

	-- Show loading indicator
	vim.notify("Fetching with nurl...", vim.log.levels.INFO)

	-- Use jobstart to capture stdout separately (already async)
	local stdout = {}
	local stderr = {}

	local job_id = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(stdout, line)
					end
				end
			end
		end,
		on_stderr = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(stderr, line)
					end
				end
			end
		end,
		on_exit = vim.schedule_wrap(function(_, exit_code)
			if exit_code ~= 0 then
				local error_msg = table.concat(stderr, "\n")
				vim.notify("nurl failed: " .. error_msg, vim.log.levels.ERROR)
				return
			end

			-- Add indentation to each line of output
			local lines = {}
			for i, line in ipairs(stdout) do
				if i == 1 then
					-- First line continues from cursor position
					table.insert(lines, line)
				else
					-- Subsequent lines get full indentation
					table.insert(lines, indent .. line)
				end
			end

			-- Add semicolon to the last line
			if #lines > 0 then
				lines[#lines] = lines[#lines] .. ";"
			end

			-- Insert the output at cursor position
			if #lines > 0 then
				vim.api.nvim_buf_set_text(buf, row - 1, col, row - 1, col, lines)
				vim.notify("nurl output inserted", vim.log.levels.INFO)
			else
				vim.notify("nurl returned no output", vim.log.levels.WARN)
			end
		end),
	})

	if job_id <= 0 then
		vim.notify("Failed to start nurl", vim.log.levels.ERROR)
	end
end, {
	nargs = "+",
	desc = "Run nurl and insert output at cursor position",
})
