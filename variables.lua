-- variables.lua

local variables = {}

-- gaps
variables.gaps = function(value)
	 local gaps = tonumber(value)
	 if gaps then
			print("Setting gaps to:", gaps)
			wm.cfg.window_gap = gaps
	 else
			print("Invalid gaps value:", value)
	 end
	 arrange()
end

-- border
variables.border = function(value)
	 local border = tonumber(value)
	 if border then
			print("Setting border to:", border)
			wm.cfg.border_width = border
	 else
			print("Invalid border value:", value)
	 end
	 rebuild_all_decorations()
	 arrange()
end

-- statusbar_height
variables.statusbar_height = function(value)
	 local statusbar_height = tonumber(value)
	 if statusbar_height then
			print("Setting statusbar_height to:", statusbar_height)
			wm.cfg.statusbar_height = statusbar_height
	 else
			print("Invalid statusbar_height value:", statusbar_height)
	 end
	 arrange()
end

-- fuse_tags
variables.fuse_tags = function(tag_one, tag_two)
	 local tone = tonumber(tag_one)
	 local ttwo = tonumber(tag_two)

	 if tone and ttwo then
			print("fusing tags:", tone, ttwo)
			fuse_tags(tone, ttwo)
			view_tag(tone)
	 else
			print("Invalid tags to fuse", tone, ttwo)
	 end
end

-- view tag
variables.view_tag = function(tag)
	 local tone = tonumber(tag)

	 if tone then
			print("fusing tags:", tone)
			view_tag(tone)
	 else
			print("Invalid tag", tone)
	 end
end

-- window position for a particular tag
variables.window_pos = function(aident, atag, pos_x, pos_y)
	 local ident = tostring(aident)
	 local x = tonumber(pos_x)
	 local y = tonumber(pos_y)
	 local tag = tonumber(atag)

	 if wm.windows then
			for _, wnd in pairs(wm.windows) do -- Use pairs here
				 if wnd.ident == ident then
						wnd.force_size = false
						wnd.tags[tag] = {
							 width = wnd.tags[tag].width,
							 height = wnd.tags[tag].height,
							 x = x,
							 y = y,
						}
						wnd:move(x, y)
				 end
			end
			arrange()
	 end
end

-- window size for a particular tag
variables.window_size = function(aident, atag, awidth, aheight)
	 local ident = tostring(aident)
	 local width = tonumber(awidth)
	 local height = tonumber(aheight)
	 local tag = tonumber(atag)

	 if wm.windows then
			for _, wnd in pairs(wm.windows) do -- Use pairs here
				 if wnd.ident == ident then
						wnd.force_size = false
						wnd.tags[tag] = {
							 width = width,
							 height = height,
							 x = wnd.tags[tag].x,
							 y = wnd.tags[tag].y,
						}
						wnd:resize(width, height)
				 end
			end
			arrange()
	 end
end

-- remove window decorations for a particular window
variables.window_no_decor = function(aident, decor)
	 local ident = tostring(aident)
	 local decorations = toboolean(decor)

	 if wm.windows then
			for _, wnd in pairs(wm.windows) do -- Use pairs here
				 if wnd.ident == ident then
						wnd.decorations = decorations
						build_decorations(wnd, { no_decor = decorations })
				 end
			end
			arrange()
	 end
end

-- variables["gaps"] = variables.gaps
-- variables["border"] = variables.border
-- variables["statusbar_height"] = variables.statusbar_height
-- variables["fuse_tags"] = variables.fuse_tags
-- variables["view_tag"] = variables.view_tag
-- variables["window_pos"] = variables.window_pos
-- variables["window_size"] = variables.window_size
-- variables["window_no_decor"] = variables.window_no_decor

return variables
