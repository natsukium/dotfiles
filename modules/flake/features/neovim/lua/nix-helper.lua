-- Convert Nix flake references to browser-openable URLs
-- Nix flakes use shorthand notation (e.g., github:owner/repo) that isn't recognized
-- as a URL by default. This function translates these references to browser-openable URLs.
-- See: https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake.html#url-like-syntax
--
-- Supported formats:
--   github:owner/repo                         -> https://github.com/owner/repo
--   github:owner/repo/ref                     -> https://github.com/owner/repo/tree/ref
--   github:owner/repo?ref=main                -> https://github.com/owner/repo/tree/main
--   gitlab:owner/repo                         -> https://gitlab.com/owner/repo
--   gitlab:owner/repo?host=gitlab.example.com -> https://gitlab.example.com/owner/repo
--   sourcehut:~user/repo                      -> https://git.sr.ht/~user/repo
--   git+https://example.org/repo              -> https://example.org/repo
--   git+ssh://git@github.com/owner/repo       -> https://github.com/owner/repo
--   git://github.com/owner/repo               -> https://github.com/owner/repo
--   hg+https://example.org/repo               -> https://example.org/repo
--   tarball+https://example.org/file.tar.gz   -> https://example.org/file.tar.gz
--   file+https://example.org/flake.nix        -> https://example.org/flake.nix
local function flake_ref_to_url(text)
	local base, query = text:match("^([^?]+)%??(.*)")
	base = base or text

	local params = {}
	for k, v in (query or ""):gmatch("([^&=]+)=([^&]+)") do
		params[k] = v
	end

	-- Forge hosting services: github:, gitlab:, sourcehut:
	local forges = {
		{ "github:", "github.com", "tree" },
		{ "gitlab:", params.host or "gitlab.com", "-/tree" },
		{ "sourcehut:", "git.sr.ht", nil },
	}
	for _, forge in ipairs(forges) do
		local prefix, host, tree_path = forge[1], forge[2], forge[3]
		local path = base:match("^" .. prefix:gsub("([%.%+])", "%%%1") .. "(.+)")
		if path then
			local owner, repo, ref = path:match("^([^/]+)/([^/]+)/?(.*)$")
			if owner and repo and tree_path then
				ref = (ref ~= "" and ref) or params.ref or params.rev
				if ref and ref ~= "" then
					return ("https://%s/%s/%s/%s/%s"):format(host, owner, repo, tree_path, ref)
				end
			end
			return "https://" .. host .. "/" .. path
		end
	end

	-- URL-like schemes: git+https://, hg+https://, tarball+https://, etc.
	local schemes = {
		"^git%+https://",
		"^git%+ssh://git@",
		"^git%+ssh://",
		"^git://",
		"^hg%+https?://",
		"^tarball%+https?://",
		"^file%+https?://",
	}
	for _, pattern in ipairs(schemes) do
		local rest = base:match(pattern .. "(.+)")
		if rest then
			return "https://" .. rest
		end
	end

	return nil
end

-- Add ':' to isfname so <cfile> captures flake refs like "github:owner/repo"
vim.opt_local.isfname:append(":")

vim.keymap.set("n", "gx", function()
	local cfile = vim.fn.expand("<cfile>")
	local url = flake_ref_to_url(cfile)
	if url then
		vim.ui.open(url)
	else
		vim.ui.open(cfile)
	end
end, { buffer = true, desc = "Open URL or Nix flake reference in browser" })

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
