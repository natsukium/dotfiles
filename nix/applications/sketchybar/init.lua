local colors = require("colors")

sbar.bar({
	height = 30,
	position = "left",
	color = colors.transparent,
	sticky = true,
	blur_radius = 30,
	topmost = "window",
	margin = 10,
})

local font = "Liga HackGen Console NF"

-- Equivalent to the --default domain
sbar.default({
	updates = "when_shown",
	icon = {
		font = {
			family = font,
			style = "Bold",
			size = 16.0,
		},
		color = colors.base07,
		width = 30,
		align = "center",
	},
	label = {
		font = {
			family = font,
			style = "Bold",
			size = 14.0,
		},
		color = colors.base07,
		width = 0, -- for two rows
		y_offset = -10, -- for two rows
		padding_left = -20, --for two rows
		padding_right = -20, --for two rows
	},
	background = {
		height = 30,
		corner_radius = 5,
		border_width = 2,
		color = colors.base01,
		border_color = colors.base03,
	},
	padding_left = 5,
	padding_right = 5,
})

local battery = sbar.add("item", {
	position = "right",
	icon = {
		font = {
			style = "Regular",
			size = 19.0,
		},
	},
	update_freq = 120,
})

local function battery_update()
	local file = assert(io.popen("pmset -g batt"))
	local batt_info = assert(file:read("a"))
	local icon = ""
	local found, _, percentage = batt_info:find("(%d+)%%")

	if string.find(batt_info, "AC Power") then
		icon = "󰂄"
	else
		if found then
			charge = tonumber(percentage)
		end

		if found and charge > 80 then
			icon = "󰂂"
		elseif found and charge > 60 then
			icon = "󰂀"
		elseif found and charge > 40 then
			icon = "󰁾"
		elseif found and charge > 20 then
			icon = "󰁼"
		else
			icon = "󰁺"
		end
	end

	battery:set({
		icon = {
			string = icon,
			width = 30,
			align = "center",
			y_offset = 10, --for two rows
		},
		label = {
			string = percentage .. "%",
			padding_left = -26,
		},
		background = { height = 60 }, --for two rows
	})
end

battery:subscribe({ "routine", "power_source_change", "system_woke" }, battery_update)

local weather = sbar.add("item", {
	position = "right",
	icon = {
		font = {
			style = "Noto Emoji",
			size = 19.0,
		},
	},
	update_freq = 120,
})

local function weather_update()
	local utf8 = require("lua-utf8")

	local wttrin = "https://wttr.in?M&format=%c+%t+%w+%p"

	local file = assert(io.popen(string.format("curl '%s'", wttrin)))
	local result = assert(file:read("a"))

	weather:set({
		icon = utf8.sub(result, 1, 1),
		label = utf8.sub(result, 2, -1),
	})
end

weather:subscribe({ "routine", "system_woke" }, weather_update)

require("items.spaces")

local time = sbar.add("item", {
	label = {
		align = "right",
	},
	position = "right",
	update_freq = 15,
})

local function update()
	time:set({
		icon = {
			string = os.date("%H"),
			y_offset = 10,
			font = { size = 16 },
			width = 30,
			align = "center",
		},
		label = {
			string = os.date("%M"),
			font = { size = 16 },
			padding_right = 10,
			width = 0,
			align = "center",
		},
		background = { height = 60 },
	})
end

time:subscribe("routine", update)
time:subscribe("forced", update)

local date = sbar.add("item", {
	label = {
		align = "right",
	},
	position = "right",
	update_freq = 15,
})

local function update()
	date:set({
		icon = {
			string = os.date("%B"):sub(1, 3),
			y_offset = 10,
			font = { size = 16 },
			width = 30,
			align = "center",
		},
		label = {
			string = os.date("%d"),
			font = { size = 16 },
			padding_right = 10,
			width = 0,
			align = "center",
		},
		background = { height = 60 },
	})
end

date:subscribe("routine", update)
date:subscribe("forced", update)
