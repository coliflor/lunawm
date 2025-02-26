local actions = {};

-- chain window
local function wrun(fun)
	 return function()
			if (priowin ~= nil) then
				 fun(priowin);
			end
	 end
end

actions.test = function()
	 local tag = tags and tags[current_tag] or {} -- Get the current tag's windows
	 local n = #tag -- Number of windows on the current tag

	 local w, h -- Initialize width and height

	 if n == 0 then -- No windows yet, take full screen
			w = VRESW
			h = VRESH
	 elseif n == 1 then -- One window (master), take master area
			w = VRESW * priocfg.master_ratio
			h = VRESH
	 else -- More than one window, calculate stack area
			w = VRESW * (1 - priocfg.master_ratio) -- Stack area width
			h = VRESH / (n) -- Stack area height (adjust as needed for your layout)
	 end

	 create_terminal(0, 0, w, h)
end
actions.shutdown = function()
	 shutdown();
end

actions.reset = function()
	 system_collapse();
end

local function view_tag(tag_number, wnd)
    current_tag = tag_number;

    -- Create a snapshot of the target tag's windows
    local target_tag_windows = {};
    if (tags[tag_number]) then
        for _, tag_wnd in ipairs(tags[tag_number]) do
            table.insert(target_tag_windows, tag_wnd);
        end
    end

    -- Show all windows in the target tag, even if they were previously hidden
    for _, tag_wnd in ipairs(target_tag_windows) do
        if (tag_wnd and type(tag_wnd.show) == "function") then
            tag_wnd:show();
        end
    end

    -- Hide all windows not in the target tag, except the focused window
    for _, other_wnd in ipairs(prio_windows_linear(false)) do
        if (other_wnd ~= wnd) then
            local found = false;
            for _, tag_wnd in ipairs(target_tag_windows) do
                if (tag_wnd == other_wnd) then
                    found = true;
                    break;
                end
            end
            if (not found) then
                other_wnd:hide();
            end
        end
    end

    -- Debug: Print the windows in the current tag
    print("Tag " .. tag_number .. " windows:");
    if (tags[tag_number]) then
        for _, tag_wnd in ipairs(tags[tag_number]) do
            if (tag_wnd and tag_wnd.id) then
                print("  Window ID: " .. tag_wnd.id);
            else
                print("  Window (no ID or invalid)");
            end
        end
    else
        print("  (No windows in this tag)");
    end
end

actions.view_tag_1 = wrun(function(wnd)
    view_tag(1, wnd);
end);

actions.view_tag_2 = wrun(function(wnd)
    view_tag(2, wnd);
end);

actions.destroy_active_tab = wrun(function(wnd) wnd:lost(wnd.target); end);
actions.destroy_active_window = wrun(function(wnd) wnd:destroy(); end);
actions.select_tab_1 = wrun(function(wnd) wnd:set_tab(1); end);
actions.select_tab_2 = wrun(function(wnd) wnd:set_tab(2); end);
actions.select_tab_3 = wrun(function(wnd) wnd:set_tab(3); end);
actions.select_tab_4 = wrun(function(wnd) wnd:set_tab(4); end);
actions.select_tab_5 = wrun(function(wnd) wnd:set_tab(5); end);
actions.select_tab_6 = wrun(function(wnd) wnd:set_tab(6); end);
actions.select_tab_7 = wrun(function(wnd) wnd:set_tab(7); end);
actions.select_tab_8 = wrun(function(wnd) wnd:set_tab(8); end);
actions.select_tab_9 = wrun(function(wnd) wnd:set_tab(9); end);
actions.select_tab_10= wrun(function(wnd) wnd:set_tab(10);end);
actions.next_tab     = wrun(function(wnd) wnd:set_tab(-2);end);
actions.prev_tab     = wrun(function(wnd) wnd:set_tab(-1);end);
actions.paste        = wrun(function(wnd) wnd:paste(CLIPBOARD_MESSAGE);end);
actions.select_up    = wrun(function(wnd) prio_sel_nearest(wnd, "t"); end);
actions.select_down  = wrun(function(wnd) prio_sel_nearest(wnd, "b"); end);
actions.select_left  = wrun(function(wnd) prio_sel_nearest(wnd, "l"); end);
actions.select_right = wrun(function(wnd) prio_sel_nearest(wnd, "r"); end);

actions.shrink_h = wrun(function(wnd) wnd:step_sz(1, 0,-1); end);
actions.shrink_w = wrun(function(wnd) wnd:step_sz(1,-1, 0); end);
actions.grow_h   = wrun(function(wnd) wnd:step_sz(1, 0, 1); end);
actions.grow_w   = wrun(function(wnd) wnd:step_sz(1, 1, 0); end);

actions.move_up    = wrun(function(wnd) wnd:step_move(1, 0,-1); end);
actions.move_down  = wrun(function(wnd) wnd:step_move(1, 0, 1); end);
actions.move_left  = wrun(function(wnd) wnd:step_move(1,-1, 0); end);
actions.move_right = wrun(function(wnd) wnd:step_move(1, 1, 0); end);

actions.toggle_maximize = wrun(function(wnd) wnd:maximize("f"); end);
actions.assign_top      = wrun(function(wnd) wnd:maximize("t"); end);
actions.assign_bottom   = wrun(function(wnd) wnd:maximize("b"); end);
actions.assign_left     = wrun(function(wnd) wnd:maximize("l"); end);
actions.assign_right    = wrun(function(wnd) wnd:maximize("r"); end);

actions.set_temp_prefix_1 = function() priosym.prefix = "t1_"; end

actions.hide = wrun(function(wnd) wnd:hide(); end);
actions.copy = wrun(function(wnd)
			if (wnd.clipboard_msg) then
				 prioclip = wnd.clipboard_msg;
			end
end);
actions.paste = wrun(function(wnd)
			wnd:paste(CLIPBOARD_MESSAGE);
end);

return actions;
