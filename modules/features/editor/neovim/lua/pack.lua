local M = {}

local loaded = {}

---@param name string directory name under `pack/*/opt/`
---@param config? fun()
function M.add(name, config)
	if loaded[name] then
		return
	end
	loaded[name] = true
	vim.cmd.packadd(name)
	if config then
		config()
	end
end

---@param event string
---@return table<string, true>
local function augroups(event)
	local names = {}
	for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = event })) do
		if autocmd.group_name then
			names[autocmd.group_name] = true
		end
	end
	return names
end

---@param event string|string[]
---@param load fun()
---@param pattern? string|string[]
function M.on_event(event, load, pattern)
	local fired = false
	vim.api.nvim_create_autocmd(event, {
		pattern = pattern,
		once = true,
		nested = true,
		callback = function(ev)
			-- `once` is per event, so a multi-event trigger can fire twice.
			if fired then
				return
			end
			fired = true

			-- The event is replayed so the autocommands the load just registered
			-- still see the buffer that triggered it. Replaying into groups that
			-- already existed would run them a second time, except for FileType:
			-- ftplugin files hang off Neovim's own long-lived group.
			if ev.event == "FileType" then
				load()
				vim.api.nvim_exec_autocmds(ev.event, { buffer = ev.buf, modeline = false, data = ev.data })
				return
			end

			local before = augroups(ev.event)
			load()
			for name in pairs(augroups(ev.event)) do
				if not before[name] then
					vim.api.nvim_exec_autocmds(ev.event, {
						group = name,
						buffer = ev.buf,
						modeline = false,
						data = ev.data,
					})
				end
			end
		end,
	})
end

---@param filetype string|string[]
---@param load fun()
function M.on_ft(filetype, load)
	M.on_event("FileType", load, filetype)
end

---@class pack.KeySpec
---@field [1] string
---@field mode? string|string[]
---@field desc? string
---@field nowait? boolean

---@param keys (string|pack.KeySpec)[]
---@param load fun()
function M.on_key(keys, load)
	for _, key in ipairs(keys) do
		local spec = type(key) == "string" and { key } or key
		local lhs = spec[1]
		local modes = spec.mode or "n"
		modes = type(modes) == "string" and { modes } or modes

		vim.keymap.set(modes, lhs, function()
			for _, mode in ipairs(modes) do
				pcall(vim.keymap.del, mode, lhs)
			end
			load()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Ignore>" .. lhs, true, true, true), "i", false)
		end, {
			-- An expression mapping that returns nothing keeps operator-pending
			-- mappings working while the real keys are fed back.
			expr = true,
			desc = spec.desc,
			nowait = spec.nowait,
		})
	end
end

---@param cmds string[]
---@param load fun()
function M.on_cmd(cmds, load)
	for _, cmd in ipairs(cmds) do
		local function replace()
			vim.api.nvim_del_user_command(cmd)
			load()
		end

		vim.api.nvim_create_user_command(cmd, function(ev)
			replace()
			local info = vim.api.nvim_get_commands({})[cmd] or vim.api.nvim_buf_get_commands(0, {})[cmd]
			if not info then
				vim.notify("Command " .. cmd .. " not found after loading", vim.log.levels.ERROR)
				return
			end

			local command = {
				cmd = cmd,
				bang = ev.bang or nil,
				mods = ev.smods,
				args = ev.fargs,
				nargs = info.nargs,
				count = ev.count >= 0 and ev.range == 0 and ev.count or nil,
			}
			if ev.range == 1 then
				command.range = { ev.line1 }
			elseif ev.range == 2 then
				command.range = { ev.line1, ev.line2 }
			end
			-- The stub takes `nargs = "*"`, so a real command taking a single
			-- argument would otherwise receive it split on whitespace.
			if ev.args ~= "" and info.nargs and info.nargs:find("[1?]") then
				command.args = { ev.args }
			end
			vim.cmd(command)
		end, {
			bang = true,
			range = true,
			nargs = "*",
			complete = function(_, line)
				replace()
				return vim.fn.getcompletion(line, "cmdline")
			end,
		})
	end
end

local deferring = false

--- Run `load` once the UI is up and the first screen has been drawn.
---@param load fun()
function M.later(load)
	vim.api.nvim_create_autocmd("User", {
		pattern = "DeferredUIEnter",
		once = true,
		nested = true,
		callback = load,
	})

	if deferring then
		return
	end
	deferring = true

	local fire = vim.schedule_wrap(function()
		if vim.v.exiting ~= vim.NIL then
			return
		end
		vim.api.nvim_exec_autocmds("User", { pattern = "DeferredUIEnter", modeline = false })
	end)
	-- UIEnter has already passed when a UI attaches to a running instance.
	if vim.v.vim_did_enter == 1 then
		fire()
	else
		vim.api.nvim_create_autocmd("UIEnter", { once = true, nested = true, callback = fire })
	end
end

return M
