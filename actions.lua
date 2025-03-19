local actions = {}

-- chain window
local function wrun(fun)
	 return function()
			if wm.window ~= nil and wm.window.canvas then
				 fun(wm.window)
			end
	 end
end

actions.terminal = function() wm.terminal() end
actions.shutdown = function() shutdown() end
actions.reset = function() system_collapse() end

actions.view_tag = function(tag_number)
	 if wm.current_tag == tag_number then
			return -- Do nothing if already on the target tag
	 end

	 local previous_tag = wm.current_tag
	 wm.last_tag = previous_tag
	 wm.current_tag = tag_number

	 local target_windows = wm.tags[tag_number] or {}
	 local previous_windows = wm.tags[previous_tag] or {}

	 -- Show target windows
	 for _, wnd in ipairs(target_windows) do
			if wnd and type(wnd.show) == "function" then
				 if wnd.tags[tag_number] and wnd.tags[tag_number].width and wnd.tags[tag_number].height then
						wnd:resize(wnd.tags[tag_number].width, wnd.tags[tag_number].height)
						wnd:move(wnd.tags[tag_number].x, wnd.tags[tag_number].y)
				 end
				 wnd:show()
			end
	 end

	 -- Hide previous windows
	 for _, wnd in ipairs(previous_windows) do
			if wnd and type(wnd.hide) == "function" then
				 wnd:hide()
			end
	 end

	 wm.arrange()
end

local function swap_last_current_tag()
	 if not wm.last_tag then
			print("swap_last_current_tag: No last tag recorded.")
			return
	 end

	 local current_tag = wm.current_tag
	 local last_tag = wm.last_tag

	 -- Swap the tags
	 actions.view_tag(last_tag)

	 print("swap_last_current_tag: Swapped tags", current_tag, "and", last_tag)
end

actions.view_tag_1 = function() actions.view_tag(1) end
actions.view_tag_2 = function() actions.view_tag(2) end
actions.view_tag_3 = function() actions.view_tag(3) end
actions.view_tag_4 = function() actions.view_tag(4) end
actions.view_tag_5 = function() actions.view_tag(5) end

actions.swap_last_current_tag = function() swap_last_current_tag() end

actions.destroy_active_window = wrun(function(wnd) wnd:destroy() end)

actions.shrink_h = wrun(function(wnd) wnd:step_sz(1, 0,-1) wnd.tags[wm.current_tag].force_size = false wm.arrange() end)
actions.shrink_w = wrun(function(wnd) wnd:step_sz(1,-1, 0) wnd.tags[wm.current_tag].force_size = false wm.arrange() end)
actions.grow_h   = wrun(function(wnd) wnd:step_sz(1, 0, 1) wnd.tags[wm.current_tag].force_size = false wm.arrange() end)
actions.grow_w   = wrun(function(wnd) wnd:step_sz(1, 1, 0) wnd.tags[wm.current_tag].force_size = false wm.arrange() end)

actions.move_up    = wrun(function(wnd)
			wnd:step_move(1, 0,-1)
			wnd.tags[wm.current_tag].force_size = false
			wm.arrange()
end)
actions.move_down  = wrun(function(wnd)
			wnd:step_move(1, 0, 1)
			wnd.tags[wm.current_tag].force_size = false
			wm.arrange()
end)
actions.move_left  = wrun(function(wnd)
			wnd:step_move(1,-1, 0)
			wnd.tags[wm.current_tag].force_size = false
			wm.arrange()
end)
actions.move_right = wrun(function(wnd)
			wnd:step_move(1, 1, 0)
			wnd.tags[wm.current_tag].force_size = false
			wm.arrange()
end)

actions.toggle_maximize = wrun(function(wnd) wnd:maximize("f") end)
actions.assign_top      = wrun(function(wnd) wnd:maximize("t") end)
actions.assign_bottom   = wrun(function(wnd) wnd:maximize("b") end)
actions.assign_left     = wrun(function(wnd) wnd:maximize("l") end)
actions.assign_right    = wrun(function(wnd) wnd:maximize("r") end)

actions.set_temp_prefix_1 = function() wm.sym.prefix = "t1_" end

actions.hide = wrun(function(wnd) wnd:hide() end)
actions.copy = wrun(function(wnd)
			if (wnd.clipboard_msg) then
				 wm.clip = wnd.clipboard_msg
			end
end)
actions.paste = wrun(function(wnd)
			wnd:paste(wm.CLIPBOARD_MESSAGE)
end)

-- Layout cycling
local current_layout_index = 1

actions.cycle_layout = function()
	 current_layout_index = (current_layout_index % #wm.layout_modes) + 1
	 local next_layout = wm.layout_modes[current_layout_index]
	 wm.set_layout_mode(next_layout)
end

actions.cycle_layout_negative = function()
	 current_layout_index = (current_layout_index - 2) % #wm.layout_modes + 1
	 if current_layout_index < 1 then
			current_layout_index = current_layout_index + #wm.layout_modes
	 end
	 local prev_layout = wm.layout_modes[current_layout_index]
	 wm.set_layout_mode(prev_layout)
end

-- Function to rotate through the window stack (positive direction) within the current tag
actions.rotate_window_stack = function()
	 local current_tag_windows = wm.tags[wm.current_tag]

	 if not current_tag_windows or #current_tag_windows <= 1 then
			return -- No windows in the current tag or only one window
	 end

	 local current_index = nil
	 for i, wnd in ipairs(current_tag_windows) do
			if (wnd == wm.window) then
				 current_index = i
				 break
			end
	 end

	 if (current_index == nil) then
			return -- Current window not found in the current tag
	 end

	 local next_index = (current_index % #current_tag_windows) + 1
	 local next_window = current_tag_windows[next_index]

	 if (next_window) then
			next_window:select()
	 end
end

-- Function to rotate through the window stack (negative direction) within the current tag
actions.rotate_window_stack_negative = function()
	 local current_tag_windows = wm.tags[wm.current_tag]

	 if not current_tag_windows or #current_tag_windows <= 1 then
			return -- No windows in the current tag or only one window
	 end

	 local current_index = nil
	 for i, wnd in ipairs(current_tag_windows) do
			if (wnd == wm.window) then
				 current_index = i
				 break
			end
	 end

	 if (current_index == nil) then
			return -- Current window not found in the current tag
	 end

	 local prev_index = current_index - 1
	 if (prev_index < 1) then
			prev_index = #current_tag_windows
	 end

	 local prev_window = current_tag_windows[prev_index]

	 if (prev_window) then
			prev_window:select()
	 end
end

local previous_selected_window = nil -- Global variable to store the previously selected window

actions.swap_master = function()
	 local tag = wm.tags and wm.tags[wm.current_tag] or {}
	 local n = #tag

	 if n <= 1 then
			return -- Nothing to swap if there are 0 or 1 windows
	 end

	 if not wm.window then
			return -- No window selected
	 end

	 local master = tag[1]
	 if master == wm.window then
			-- If the master is selected, swap with a child window
			local swap_index = 2 -- Default to the first child

			-- If a previous selected window exists, use it if it is a child.
			if previous_selected_window and previous_selected_window ~= master then
				 for i, wnd in ipairs(tag) do
						if wnd == previous_selected_window then
							 swap_index = i
							 break
						end
				 end
			end

			if swap_index then
				 tag[1], tag[swap_index] = tag[swap_index], tag[1]
				 wm.arrange()
			end
			return -- Exit after swapping
	 end

	 local master_index = 1
	 local selected_index = nil

	 for i, wnd in ipairs(tag) do
			if wnd == wm.window then
				 selected_index = i
				 break
			end
	 end

	 if selected_index == nil then
			return -- Selected window not found in the tag
	 end

	 -- Update the previous selected window before swapping
	 previous_selected_window = master

	 -- Swap the windows in the tag table
	 tag[master_index], tag[selected_index] = tag[selected_index], tag[master_index]

	 wm.arrange() -- Re-arrange the windows
end

actions.swap_child_windows = function()
	 local tag = wm.tags and wm.tags[wm.current_tag] or {}
	 local n = #tag

	 if n <= 2 then
			return -- Nothing to swap if there are 0, 1, or 2 windows
	 end

	 if not wm.window then
			return -- No window selected
	 end

	 local window_index = nil
	 for i, wnd in ipairs(tag) do
			if wnd == wm.window then
				 window_index = i
				 break
			end
	 end

	 if not window_index or window_index == 1 then
			return -- Selected window not found or is the master
	 end

	 local swap_index = window_index + 1
	 if swap_index > n then
			swap_index = 2 -- Wrap around to the first child
	 end

	 -- Swap the windows
	 tag[window_index], tag[swap_index] = tag[swap_index], tag[window_index]

	 wm.arrange() -- Re-arrange the windows
end

actions.swap_child_windows_negative = function()
	 local tag = wm.tags and wm.tags[wm.current_tag] or {}
	 local n = #tag

	 if n <= 2 then
			return -- Nothing to swap if there are 0, 1, or 2 windows
	 end

	 if not wm.window then
			return -- No window selected
	 end

	 local window_index = nil
	 for i, wnd in ipairs(tag) do
			if wnd == wm.window then
				 window_index = i
				 break
			end
	 end

	 if not window_index or window_index == 1 then
			return -- Selected window not found or is the master
	 end

	 local swap_index = window_index - 1
	 if swap_index < 2 then
			swap_index = n -- Wrap around to the last child
	 end

	 -- Swap the windows
	 tag[window_index], tag[swap_index] = tag[swap_index], tag[window_index]

	 wm.arrange() -- Re-arrange the windows
end

-- Function to increase master window width
actions.increase_master_width = function()
	 local current_tag_data = wm.tags[wm.current_tag]

	 if current_tag_data then
			if current_tag_data.master_ratio == nil then
				 current_tag_data.master_ratio = 0.5 -- Initialize with default if nil
			end

			-- Increase by 5%, limit to 95%
			current_tag_data.master_ratio = math.min(current_tag_data.master_ratio + 0.05, 0.95)
			print("Master ratio for tag", wm.current_tag, "increased to:", current_tag_data.master_ratio)
			wm.arrange()
	 else
			print("Error: Current tag data not found.")
	 end
end
-- Function to decrease master window width
actions.decrease_master_width = function()
	 local current_tag_data = wm.tags[wm.current_tag]

	 if current_tag_data then
			if current_tag_data.master_ratio == nil then
				 current_tag_data.master_ratio = 0.5 -- Initialize with default if nil
			end

			-- Decrease by 5%, limit to 10%
			current_tag_data.master_ratio = math.max(current_tag_data.master_ratio - 0.05, 0.10)
			print("Master ratio for tag", wm.current_tag, "decreased to:", current_tag_data.master_ratio)
			wm.arrange()
	 else
			print("Error: Current tag data not found.")
	 end
end
local function assign_tag(tag_index, wnd)
	 if not wnd then
			return -- No window provided
	 end

	 -- Check if the window is already in the tag
	 local found = false
	 local found_index = nil
	 for i, existing_wnd in ipairs(wm.tags[tag_index]) do
			if existing_wnd == wnd then
				 found = true
				 found_index = i
				 break
			end
	 end

	 if found then
			-- Remove the window from the tag if it's already there
			local tag_count = 0;
			for _, tag in pairs(wm.tags) do
				 for _, window in ipairs(tag) do
						if window == wnd then
							 tag_count = tag_count + 1;
							 break;
						end
				 end
			end

			if tag_count > 1 then
				 table.remove(wm.tags[tag_index], found_index)
			end
			--view_tag(wm.current_tag)
	 else
			-- Add the window to the tag if it's not already there
			table.insert(wm.tags[tag_index], wnd)
	 end
end

actions.assign_tag_1 = wrun(function(wnd) assign_tag(1, wnd) end)
actions.assign_tag_2 = wrun(function(wnd) assign_tag(2, wnd) end)
actions.assign_tag_3 = wrun(function(wnd) assign_tag(3, wnd) end)
actions.assign_tag_4 = wrun(function(wnd) assign_tag(4, wnd) end)
actions.assign_tag_5 = wrun(function(wnd) assign_tag(5, wnd) end)

actions.fuse_tags = function(tag_index1, tag_index2)
	 -- Check if the tags exist
	 if not wm.tags[tag_index1] or not wm.tags[tag_index2] then
			print("fuse_tags: One or both tags do not exist.")
			return
	 end

	 -- Reassign windows from tag_index2 to tag_index1
	 for _, wnd in ipairs(wm.tags[tag_index2]) do
			assign_tag(tag_index1, wnd)
	 end

   -- Remove tag index from windows in tag_index2
	 for _, wnd in ipairs(wm.tags[tag_index2]) do
			assign_tag(tag_index2, wnd)
	 end

	 -- Reset tag_index2
	 --wm.tags[tag_index2] = {}

	 print("fuse_tags: Tag", tag_index2, "fused into tag", tag_index1)
end

-- TODO: not working properly
local function fuse_all_tags()
	 local num_tags = #wm.tags

	 if num_tags <= 1 then
			print("fuse_all_tags: There are not enough tags to fuse.")
			return
	 end

	 -- Fuse all tags into the first tag (index 1)
	 for i = num_tags, 2, -1 do -- Iterate from the last tag to the second tag
			if wm.tags[i] then
				 actions.fuse_tags(1, i) -- Fuse tag 'i' into tag 1
			end
	 end

	 wm.view_tag(1)
	 wm.arrange() -- Re-arrange windows

	 print("fuse_all_tags: All tags fused into tag 1.")
end

actions.fuse_all_tags = function() fuse_all_tags() end

local function move_window_to_tag(wnd, target_tag_index)
	 if not wm.tags[target_tag_index] then
			print("move_window_to_tag: Target tag does not exist.")
			return
	 end

	 local current_tag_index = nil
	 for tag_index, tag in ipairs(wm.tags) do
			if tag then
				 for _, existing_wnd in ipairs(tag) do
						if existing_wnd == wnd then
							 current_tag_index = tag_index
							 break
						end
				 end
			end
			if current_tag_index then
				 break
			end
	 end

	 if not current_tag_index then
			print("move_window_to_tag: Window not found in any tag.")
			return
	 end

	 if current_tag_index == target_tag_index then
			print("move_window_to_tag: Window is already in the target tag.")
			return
	 end

	 -- Remove the window from the current tag
	 local found_index = nil
	 for i, existing_wnd in ipairs(wm.tags[current_tag_index]) do
			if existing_wnd == wnd then
				 found_index = i
				 break
			end
	 end

	 if found_index then
			table.remove(wm.tags[current_tag_index], found_index)
	 end

	 -- Add the window to the target tag
	 table.insert(wm.tags[target_tag_index], wnd)

	 wnd:hide()
	 wm.arrange() -- Re-arrange windows on both tags

	 print("move_window_to_tag: Window", wnd, "moved from tag", current_tag_index, "to tag", target_tag_index)
end

actions.move_window_to_tag_1 = wrun(function(wnd) move_window_to_tag(wnd, 1) end)
actions.move_window_to_tag_2 = wrun(function(wnd) move_window_to_tag(wnd, 2) end)
actions.move_window_to_tag_3 = wrun(function(wnd) move_window_to_tag(wnd, 3) end)
actions.move_window_to_tag_4 = wrun(function(wnd) move_window_to_tag(wnd, 4) end)
actions.move_window_to_tag_5 = wrun(function(wnd) move_window_to_tag(wnd, 5) end)

actions.window_stacked = wrun(function(wnd)  wnd.tags[wm.current_tag].force_size = true wm.arrange()  end)
actions.window_floating = wrun(function(wnd) wnd.tags[wm.current_tag].force_size = false wm.arrange() end)

actions.center_window = wrun(function(wnd)
			local screen_width = VRESW
			local screen_height = VRESH
			local window_width = wnd.tags[wm.current_tag].width
			local window_height = wnd.tags[wm.current_tag].height

			local center_x = (screen_width - window_width) / 2
			local center_y = (screen_height - window_height) / 2

			wnd.tags[wm.current_tag].force_size = false
			wnd:move(center_x, center_y)
end)

-- actions["terminal"] = actions.terminal

return actions
