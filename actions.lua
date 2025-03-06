local actions = {}

-- chain window
local function wrun(fun)
	 return function()
			if (priowin ~= nil) then
				 fun(priowin)
			end
	 end
end

actions.terminal = function()
	 terminal()
end

actions.shutdown = function()
	 shutdown()
end

actions.reset = function()
	 system_collapse()
end

local function view_tag(tag_number)
	 wm.current_tag = tag_number

	 -- Create a snapshot of the target tag's windows
	 local target_tag_windows = {}
	 if (wm.tags[tag_number]) then
			for _, tag_wnd in ipairs(wm.tags[tag_number]) do
				 table.insert(target_tag_windows, tag_wnd)
			end
	 end

	 -- Show all windows in the target tag
	 for _, tag_wnd in ipairs(target_tag_windows) do
			if (tag_wnd and type(tag_wnd.show) == "function") then
				 tag_wnd:show()
			end
	 end

	 -- Hide all windows not in the target tag
	 for _, other_wnd in ipairs(prio_windows_linear(false)) do
			local found = false
			for _, tag_wnd in ipairs(target_tag_windows) do
				 if (tag_wnd == other_wnd) then
						found = true
						break
				 end
			end
			if (not found) then
				 other_wnd:hide()
			end
	 end

	 -- Debug: Print the windows in the current tag
	 print("Tag " .. tag_number .. " windows:")
	 if (wm.tags[tag_number]) then
			for _, tag_wnd in ipairs(wm.tags[tag_number]) do
				 if (tag_wnd and tag_wnd.id) then
						print("  Window ID: " .. tag_wnd.id)
				 else
						print("  Window (no ID or invalid)")
				 end
			end
	 else
			print("  (No windows in this tag)")
	 end
end


actions.view_tag_1 = function() view_tag(1) end
actions.view_tag_2 = function() view_tag(2) end
actions.view_tag_3 = function() view_tag(3) end
actions.view_tag_4 = function() view_tag(4) end
actions.view_tag_5 = function() view_tag(5) end

actions.destroy_active_window = wrun(function(wnd) wnd:destroy() end)
actions.paste        = wrun(function(wnd) wnd:paste(CLIPBOARD_MESSAGE)end)
actions.select_up    = wrun(function(wnd) prio_sel_nearest(wnd, "t") end)
actions.select_down  = wrun(function(wnd) prio_sel_nearest(wnd, "b") end)
actions.select_left  = wrun(function(wnd) prio_sel_nearest(wnd, "l") end)
actions.select_right = wrun(function(wnd) prio_sel_nearest(wnd, "r") end)

actions.shrink_h = wrun(function(wnd) wnd:step_sz(1, 0,-1) end)
actions.shrink_w = wrun(function(wnd) wnd:step_sz(1,-1, 0) end)
actions.grow_h   = wrun(function(wnd) wnd:step_sz(1, 0, 1) end)
actions.grow_w   = wrun(function(wnd) wnd:step_sz(1, 1, 0) end)

actions.move_up    = wrun(function(wnd) wnd:step_move(1, 0,-1) end)
actions.move_down  = wrun(function(wnd) wnd:step_move(1, 0, 1) end)
actions.move_left  = wrun(function(wnd) wnd:step_move(1,-1, 0) end)
actions.move_right = wrun(function(wnd) wnd:step_move(1, 1, 0) end)

actions.toggle_maximize = wrun(function(wnd) wnd:maximize("f") end)
actions.assign_top      = wrun(function(wnd) wnd:maximize("t") end)
actions.assign_bottom   = wrun(function(wnd) wnd:maximize("b") end)
actions.assign_left     = wrun(function(wnd) wnd:maximize("l") end)
actions.assign_right    = wrun(function(wnd) wnd:maximize("r") end)

actions.set_temp_prefix_1 = function() wm.sym.prefix = "t1_" end

actions.hide = wrun(function(wnd) wnd:hide() end)
actions.copy = wrun(function(wnd)
			if (wnd.clipboard_msg) then
				 prioclip = wnd.clipboard_msg
			end
end)
actions.paste = wrun(function(wnd)
			wnd:paste(CLIPBOARD_MESSAGE)
end)

-- Layout cycling
local layout_modes = {"monocle", "grid", "master_stack", "middle_stack"}
local current_layout_index = 1

actions.cycle_layout = function()
	 current_layout_index = (current_layout_index % #layout_modes) + 1
	 local next_layout = layout_modes[current_layout_index]
	 set_layout_mode(next_layout)
	 print("Layout changed to: " .. next_layout)
end

-- Function to rotate through the window stack (positive direction) within the current tag
actions.rotate_window_stack = function()
	 local current_tag_windows = wm.tags[wm.current_tag]

	 if not current_tag_windows or #current_tag_windows <= 1 then
			return -- No windows in the current tag or only one window
	 end

	 local current_index = nil
	 for i, wnd in ipairs(current_tag_windows) do
			if (wnd == priowin) then
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
			window_select(next_window)
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
			if (wnd == priowin) then
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
			window_select(prev_window)
	 end
end

local previous_selected_window = nil -- Global variable to store the previously selected window

actions.swap_master = function()
	 local tag = wm.tags and wm.tags[wm.current_tag] or {}
	 local n = #tag

	 if n <= 1 then
			return -- Nothing to swap if there are 0 or 1 windows
	 end

	 if not priowin then
			return -- No window selected
	 end

	 local master = tag[1]
	 if master == priowin then
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
				 arrange()
			end
			return -- Exit after swapping
	 end

	 local master_index = 1
	 local selected_index = nil

	 for i, wnd in ipairs(tag) do
			if wnd == priowin then
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

	 -- Re-arrange the windows
	 arrange()
end

actions.swap_child_windows = function()
	 local tag = wm.tags and wm.tags[wm.current_tag] or {}
	 local n = #tag

	 if n <= 2 then
			return -- Nothing to swap if there are 0, 1, or 2 windows
	 end

	 if not priowin then
			return -- No window selected
	 end

	 local priowin_index = nil
	 for i, wnd in ipairs(tag) do
			if wnd == priowin then
				 priowin_index = i
				 break
			end
	 end

	 if not priowin_index or priowin_index == 1 then
			return -- Selected window not found or is the master
	 end

	 local swap_index = priowin_index + 1
	 if swap_index > n then
			swap_index = 2 -- Wrap around to the first child
	 end

	 -- Swap the windows
	 tag[priowin_index], tag[swap_index] = tag[swap_index], tag[priowin_index]

	 arrange() -- Re-arrange the windows
end

actions.swap_child_windows_negative = function()
	 local tag = wm.tags and wm.tags[wm.current_tag] or {}
	 local n = #tag

	 if n <= 2 then
			return -- Nothing to swap if there are 0, 1, or 2 windows
	 end

	 if not priowin then
			return -- No window selected
	 end

	 local priowin_index = nil
	 for i, wnd in ipairs(tag) do
			if wnd == priowin then
				 priowin_index = i
				 break
			end
	 end

	 if not priowin_index or priowin_index == 1 then
			return -- Selected window not found or is the master
	 end

	 local swap_index = priowin_index - 1
	 if swap_index < 2 then
			swap_index = n -- Wrap around to the last child
	 end

	 -- Swap the windows
	 tag[priowin_index], tag[swap_index] = tag[swap_index], tag[priowin_index]

	 arrange() -- Re-arrange the windows
end

-- Function to increase master window width
actions.increase_master_width = function()
	 wm.cfg.master_ratio = math.min(wm.cfg.master_ratio + 0.05, 0.95) -- Increase by 5%, limit to 95%
	 print("Master ratio increased to:", wm.cfg.master_ratio)
	 arrange()
end

-- Function to decrease master window width
actions.decrease_master_width = function()
	 wm.cfg.master_ratio = math.max(wm.cfg.master_ratio - 0.05, 0.10) -- Decrease by 5%, limit to 10%
	 print("Master ratio decreased to:", wm.cfg.master_ratio)
	 arrange()
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
			for t, tag in pairs(wm.tags) do
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
			arrange() -- Re-arrange windows
	 else
			-- Add the window to the tag if it's not already there
			table.insert(wm.tags[tag_index], wnd)
			arrange() -- Re-arrange windows
	 end
end

actions.assign_tag_1 = wrun(function(wnd) assign_tag(1, wnd) end)
actions.assign_tag_2 = wrun(function(wnd) assign_tag(2, wnd) end)
actions.assign_tag_3 = wrun(function(wnd) assign_tag(3, wnd) end)
actions.assign_tag_4 = wrun(function(wnd) assign_tag(4, wnd) end)
actions.assign_tag_5 = wrun(function(wnd) assign_tag(5, wnd) end)

actions["terminal"] = actions.terminal

return actions
