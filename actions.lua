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
	 prio_terminal(0, 0, 100, 100)
end

actions.shutdown = function()
	 shutdown();
end

actions.reset = function()
	 system_collapse();
end

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

--
-- others: hide all, copy, paste
--
return actions;
