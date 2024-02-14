local colors = require("colors")

-- Equivalent to the --bar domain
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
  sticky = true,
  shadow = true,
})
