local colors = require("colors")

sbar.bar({
	height = 32,
	color = colors.transparent,
	border_color = colors.bar.border,
	shadow = true,
	sticky = true,
	padding_right = 10,
	padding_left = 10,
	y_offset = 10,
	blur_radius = 30,
	topmost = "window",
	mergin = 10,
	corner_radius = 10,
})

local settings = require("settings")

-- Equivalent to the --default domain
sbar.default({
	updates = "when_shown",
	icon = {
		font = {
			family = settings.font,
			style = "Bold",
			size = 17.0,
		},
		color = colors.white,
		padding_left = 4,
		padding_right = 4,
	},
	label = {
		font = {
			family = settings.font,
			style = "Bold",
			size = 16.0,
		},
		color = colors.white,
		padding_left = 4,
		padding_right = 4,
	},
	-- background = {
	--   height = 26,
	--   corner_radius = 9,
	--   border_width = 2,
	-- },
	-- popup = {
	--   background = {
	--     border_width = 2,
	--     corner_radius = 9,
	--     border_color = colors.popup.border,
	--     color = colors.popup.bg,
	--     shadow = { drawing = true },
	--   },
	--   blur_radius = 20,
	-- },
	padding_left = 5,
	padding_right = 5,
})

local icons = require("icons")

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
		icon = icon,
		label = percentage .. "%",
		background = { color = colors.bar, drawing = true, height = 25 },
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
		background = { color = colors.bar, drawing = true, height = 25 },
	})
end

weather:subscribe({ "routine", "system_woke" }, weather_update)

require("items.apple")
require("items.spaces")

local front_app = sbar.add("item", {
	icon = {
		drawing = false,
	},
})

front_app:subscribe("front_app_switched", function(env)
	front_app:set({
		label = {
			string = env.INFO,
		},
	})
end)

local cal = sbar.add("item", {
	label = {
		align = "right",
	},
	position = "right",
	update_freq = 15,
})

local function update()
	local date = os.date("%a/%m/%d %H:%M")
	local time = os.date("%H:%M")
	cal:set({ label = date })
end

cal:subscribe("routine", update)
cal:subscribe("forced", update)

require("items.volume")
require("items.media")
