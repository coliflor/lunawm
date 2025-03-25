-- variables.lua

local variables = {}

-- gaps
variables.gaps = function(value)
	 local gaps = tonumber(value)
	 if gaps then
			if gaps >= 0 then
				 wm.cfg.window_gap = gaps
				 wm.arrange()
			end
	 end
end

-- border
variables.border = function(value)
	 local border = tonumber(value)
	 if border then
			if border >= 0 then
				 wm.cfg.border_width = border
				 wm.arrange()
			end
	 end
end

-- window gaps
variables.window_gaps = function(left, right, top, bottom)
	 local gap_left = tonumber(left)
	 local gap_right = tonumber(right)
	 local gap_top = tonumber(top)
	 local gap_bottom = tonumber(bottom)

	 local valid = true

	 -- Check for valid numbers and non-negative values
	 if gap_left == nil or gap_left < 0 then
			valid = false
	 end

	 if gap_right == nil or gap_right < 0 then
			valid = false
	 end

	 if gap_top == nil or gap_top < 0 then
			valid = false
	 end

	 if gap_bottom == nil or gap_bottom < 0 then
			valid = false
	 end

	 if valid then
			wm.cfg.window_gap_left = gap_left
			wm.cfg.window_gap_right = gap_right
			wm.cfg.window_gap_top = gap_top
			wm.cfg.window_gap_bottom = gap_bottom
			wm.arrange()
	 end
end

-- fuse_tags
variables.fuse_tags = function(tag_one, tag_two)
	 local tone = tonumber(tag_one)
	 local ttwo = tonumber(tag_two)

	 if tone and ttwo then
			print("fusing tags:", tone, ttwo)
			wm.fuse_tags(tone, ttwo)
			wm.view_tag(tone)
	 else
			print("Invalid tags to fuse", tone, ttwo)
	 end
end

-- view tag
variables.view_tag = function(tag)
	 local tone = tonumber(tag)

	 if tone then
			wm.view_tag(tone)
	 end
end

-- window position and size for a particular tag
variables.window_status = function(aident, atag, awidth, aheight, pos_x, pos_y)
	 local ident = tostring(aident)
	 local tag = tonumber(atag)

	 local function resolve_value(val)
			if type(val) == "string" then
				 local global_val = _G[val]
				 if type(global_val) == "number" then
						return global_val
				 else
						local num_val = tonumber(val)
						if num_val then
							 return num_val
						else
							 return nil
						end
				 end
			else
				 return tonumber(val)
			end
	 end

	 local width = resolve_value(awidth)
	 local height = resolve_value(aheight)
	 local x = resolve_value(pos_x)
	 local y = resolve_value(pos_y)

	 if width == nil or height == nil or tag == nil  or x == nil or y == nil then
			return
	 end

	 if wm.windows then
			for _, wnd in pairs(wm.windows) do
				 if wnd.ident == ident then

						-- Check if wnd.tags[tag] already exists
						if wnd.tags and wnd.tags[tag] then
							 wnd.tags[tag] = {}; -- Delete existing data
						end;

						-- Assign the window to the tag
						table.insert(wm.tags[tag], wnd)

						wnd.tags[tag] = {
							 width = width,
							 height = height,
							 x = x,
							 y = y,
						}

						wnd:resize(wnd.tags[tag].width, wnd.tags[tag].height)

						wnd.tags[tag].force_size = false
						break -- Exit loop after finding the window
				 end
			end
	 end
end

-- remove window decorations for a particular window
variables.window_no_decor = function(aident, decor)
	 local ident = tostring(aident)
	 local decorations = wm.toboolean(decor)

	 if wm.windows then
			for _, wnd in pairs(wm.windows) do -- Use pairs here
				 if wnd.ident == ident then
						wnd.decorations = decorations
						wnd:build_decor({ no_decor = decorations })
				 end
			end
			wm.arrange()
	 end
end

return variables
