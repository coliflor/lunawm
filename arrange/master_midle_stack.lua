local function arrange_master_middle_stack(tag)
	 local statusbar_height = wm.cfg.statusbar_height or 20
	 local statusbar_position = wm.cfg.statusbar_position or "bottom"
	 local gap = wm.cfg.window_gap or 5

	 local visible_windows = {}
	 for _, wnd in ipairs(tag) do
			if wnd.tags[wm.current_tag].force_size == true then
				 table.insert(visible_windows, wnd)
			end
	 end

	 local n = #visible_windows

	 if n == 0 then
			return
	 end

	 if n == 1 then
			arrangers.monocle(visible_windows)
			return
	 end

	 local master_ratio = wm.tags[wm.current_tag].master_ratio or 0.5

	 local master_area_w = VRESW * master_ratio
	 local master_area_h = VRESH - statusbar_height
	 local stack_area_w = (VRESW - master_area_w) / 2
	 local stack_area_h = VRESH - statusbar_height

	 -- Master window (n > 1)
	 local master = visible_windows[1]
	 local pad_w = master.margin.l + master.margin.r
	 local pad_h = master.margin.t + master.margin.b

	 local master_y = master.margin.t + gap / 2
	 if statusbar_position == "top" then
			master_y = master_y + statusbar_height
	 end

	 master:move((VRESW - master_area_w) / 2 + master.margin.l + gap / 2, master_y)
	 master:resize(master_area_w - pad_w - gap, master_area_h - pad_h - gap)

	 -- Stack windows (n > 1)
	 local left_stack = {}
	 local right_stack = {}

	 for i = 2, n do
			if i % 2 == 0 then
				 table.insert(left_stack, visible_windows[i])
			else
				 table.insert(right_stack, visible_windows[i])
			end
	 end

	 local left_n = #left_stack
	 local right_n = #right_stack

	 local left_stack_h = (stack_area_h - (left_n - 1) * gap) / left_n
	 local right_stack_h = (stack_area_h - (right_n - 1) * gap) / right_n

	 -- Left Stack
	 for i, wnd in ipairs(left_stack) do
			local pad_w = wnd.margin.l + wnd.margin.r
			local pad_h = wnd.margin.t + wnd.margin.b

			local wnd_y = (i - 1) * left_stack_h + wnd.margin.t + gap / 2 + (i - 1) * gap
			if statusbar_position == "top" then
				 wnd_y = wnd_y + statusbar_height
			end

			wnd:move(wnd.margin.l + gap / 2, wnd_y)
			wnd:resize(stack_area_w - pad_w - gap, left_stack_h - pad_h - gap)
	 end

	 -- Right Stack
	 for i, wnd in ipairs(right_stack) do
			local pad_w = wnd.margin.l + wnd.margin.r
			local pad_h = wnd.margin.t + wnd.margin.b

			local wnd_y = (i - 1) * right_stack_h + wnd.margin.t + gap / 2 + (i - 1) * gap
			if statusbar_position == "top" then
				 wnd_y = wnd_y + statusbar_height
			end

			wnd:move(VRESW - stack_area_w + wnd.margin.l + gap / 2, wnd_y)
			wnd:resize(stack_area_w - pad_w - gap, right_stack_h - pad_h - gap)
	 end
end

return arrange_master_middle_stack
