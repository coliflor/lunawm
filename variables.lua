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
	 wm.arrange()
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
	 wm.arrange()
end

-- window gaps
variables.window_gaps = function(left, right, top, bottom)
    local gap_left = tonumber(left)
    local gap_right = tonumber(right)
    local gap_top = tonumber(top)
    local gap_bottom = tonumber(bottom)

    local valid = true

    if gap_left then
        wm.cfg.window_gap_left = gap_left
    else
        print("Invalid window_gap_left value:", left)
        valid = false
    end

    if gap_right then
        wm.cfg.window_gap_right = gap_right
    else
        print("Invalid window_gap_right value:", right)
        valid = false
    end

    if gap_top then
        wm.cfg.window_gap_top = gap_top
    else
        print("Invalid window_gap_top value:", top)
        valid = false
    end

    if gap_bottom then
        wm.cfg.window_gap_bottom = gap_bottom
    else
        print("Invalid window_gap_bottom value:", bottom)
        valid = false
    end

    if valid then
        print("Setting window_gaps to: left=", gap_left, ", right=", gap_right, ", top=", gap_top, ", bottom=", gap_bottom)
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
			print("fusing tags:", tone)
			wm.view_tag(tone)
	 else
			print("Invalid tag", tone)
	 end
end

local function assign_tag(tag_index, wnd)
	 if not wnd then
			return -- No window provided
	 end

	 -- Check if the window is already in the tag
	 local found = false
	 for _, existing_wnd in ipairs(wm.tags[tag_index]) do
			if existing_wnd == wnd then
				 found = true
				 break
			end
	 end

	 if found then
			return
	 else
			-- Add the window to the tag if it's not already there
			table.insert(wm.tags[tag_index], wnd)
	 end
end

-- window position for a particular tag
-- TODO: this is garbage calling wnd:move(x, y)
variables.window_pos = function(aident, atag, pos_x, pos_y)
	 local ident = tostring(aident)
	 local x = tonumber(pos_x)
	 local y = tonumber(pos_y)
	 local tag = tonumber(atag)

	 if wm.windows then
			for _, wnd in pairs(wm.windows) do
				 if wnd.ident == ident then
						assign_tag(tag, wnd) -- Assign the window to the tag first
						wnd.tags[tag].force_size = false
						wnd:move(x, y)
						-- wnd.tags[tag] = {
						-- 	 width = wnd.tags[tag].width,
						-- 	 height = wnd.tags[tag].height,
						-- 	 x = x,
						-- 	 y = y,
						-- }
				 end
			end
	 else
			print("Error: wm.windows is nil.")
	 end
end

-- window size for a particular tag
-- TODO: this is garbage calling wnd:resize(width, height)
variables.window_size = function(aident, atag, awidth, aheight)
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

	 if width == nil or height == nil then
			print("Error: Invalid width or height provided.")
			return
	 end

	 if wm.windows then
			for _, wnd in pairs(wm.windows) do
				 if wnd.ident == ident then
						assign_tag(tag, wnd) -- Assign the window to the tag first
						wnd.tags[tag].force_size = false
						wnd:resize(width, height)
						-- wnd.tags[tag] = {
						-- 	 width = width,
						-- 	 height = height,
						-- 	 x = wnd.tags[tag].x,
						-- 	 y = wnd.tags[tag].y,
						-- }
				 end
			end
	 else
			print("Error: wm.windows is nil.")
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
						build_decorations(wnd, { no_decor = decorations })
				 end
			end
			wm.arrange()
	 end
end

-- variables["gaps"] = variables.gaps
-- variables["border"] = variables.border
-- variables["window_gaps"] = variables.window_gaps
-- variables["fuse_tags"] = variables.fuse_tags
-- variables["view_tag"] = variables.view_tag
-- variables["window_pos"] = variables.window_pos
-- variables["window_size"] = variables.window_size
-- variables["window_no_decor"] = variables.window_no_decor

return variables
