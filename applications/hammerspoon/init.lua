-- PaperWM.spoon settings
-- https://github.com/mogenson/PaperWM.spoon
PaperWM = hs.loadSpoon("PaperWM")

PaperWM.window_gap = 10
PaperWM.window_offset = { left = 40, top = 0, right = 0, bottom = 0 }
PaperWM.window_ratios = { 0.34, 0.50, 0.66 }
PaperWM.window_filter:rejectApp("CopyQ")

PaperWM.swipe_fingers = 3

PaperWM:bindHotkeys({
	-- switch to a new focused window in tiled grid
	focus_left = { { "alt" }, "h" },
	focus_right = { { "alt" }, "l" },
	focus_up = { { "alt" }, "k" },
	focus_down = { { "alt" }, "j" },

	-- move windows around in tiled grid
	swap_left = { { "alt", "shift" }, "h" },
	swap_right = { { "alt", "shift" }, "l" },
	swap_up = { { "alt", "shift" }, "k" },
	swap_down = { { "alt", "shift" }, "j" },

	-- position and resize focused window
	center_window = { { "alt" }, "c" },
	full_width = { { "alt" }, "f" },
	cycle_width = { { "alt" }, "r" },
	reverse_cycle_width = { { "alt", "shift" }, "r" },
	cycle_height = { { "ctrl", "alt" }, "r" },
	reverse_cycle_height = { { "ctrl", "alt", "shift" }, "r" },

	-- move focused window into / out of a column
	slurp_in = { { "alt", "cmd" }, "i" },
	barf_out = { { "alt", "cmd" }, "o" },

	-- move the focused window into / out of the tiling layer
	toggle_floating = { { "alt", "cmd", "shift" }, "escape" },

	-- switch to a new Mission Control space
	switch_space_l = { { "alt", "cmd" }, "," },
	switch_space_r = { { "alt", "cmd" }, "." },
	switch_space_1 = { { "alt", "cmd" }, "1" },
	switch_space_2 = { { "alt", "cmd" }, "2" },
	switch_space_3 = { { "alt", "cmd" }, "3" },
	switch_space_4 = { { "alt", "cmd" }, "4" },
	switch_space_5 = { { "alt", "cmd" }, "5" },
	switch_space_6 = { { "alt", "cmd" }, "6" },
	switch_space_7 = { { "alt", "cmd" }, "7" },
	switch_space_8 = { { "alt", "cmd" }, "8" },
	switch_space_9 = { { "alt", "cmd" }, "9" },

	-- move focused window to a new space and tile
	move_window_1 = { { "alt", "cmd", "shift" }, "1" },
	move_window_2 = { { "alt", "cmd", "shift" }, "2" },
	move_window_3 = { { "alt", "cmd", "shift" }, "3" },
	move_window_4 = { { "alt", "cmd", "shift" }, "4" },
	move_window_5 = { { "alt", "cmd", "shift" }, "5" },
	move_window_6 = { { "alt", "cmd", "shift" }, "6" },
	move_window_7 = { { "alt", "cmd", "shift" }, "7" },
	move_window_8 = { { "alt", "cmd", "shift" }, "8" },
	move_window_9 = { { "alt", "cmd", "shift" }, "9" },
})
PaperWM:start()

-- reload config on change
local function reloadConfig(files)
	local doReload = false
	for _, file in pairs(files) do
		if file:sub(-4) == ".lua" then
			doReload = true
		end
	end
	if doReload then
		hs.reload()
	end
end

myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.config/hammerspoon/", reloadConfig):start()
hs.alert.show("Config loaded")
