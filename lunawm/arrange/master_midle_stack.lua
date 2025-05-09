local function arrange_master_middle_stack(tag)
	 local gap = wm.cfg.window_gap or 5
	 local gap_top = wm.cfg.window_gap_top or 0
	 local gap_bottom = wm.cfg.window_gap_bottom or 0
	 local gap_left = wm.cfg.window_gap_left or 0
	 local gap_right = wm.cfg.window_gap_right or 0

	 local visible_windows = {}
	 for _, wnd in ipairs(tag) do
			-- Initialize wnd.tags if it's nil
			if not wnd.tags then
				 wnd.tags = {}
			end

			if wnd.tags[wm.current_tag].force_size == true then
				 table.insert(visible_windows, wnd)
			end
	 end

	 local n = #visible_windows

	 if n == 0 then
			return
	 end

	 if n == 1 then
			wm.arrangers.monocle(visible_windows)
			return
	 end

	 if n == 2 then
			wm.arrangers.master_stack(visible_windows)
			return
	 end

	 local master_ratio = wm.tags[wm.current_tag].master_ratio or 0.5

	 local master_area_w = VRESW * master_ratio
	 local master_area_h = VRESH - gap_top - gap_bottom
	 local stack_area_w = (VRESW - master_area_w - gap) / 2 -- Gap between master and stacks

	 -- Master window (n > 1)
	 local master = visible_windows[1]
	 local pad_w = master.margin.l + master.margin.r
	 local pad_h = master.margin.t + master.margin.b

	 local master_y = master.margin.t + gap / 2 + gap_top

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

	 local left_stack_h = (master_area_h - (left_n - 1) * gap) / left_n
	 local right_stack_h = (master_area_h - (right_n - 1) * gap) / right_n

	 -- Left Stack
	 for i, wnd in ipairs(left_stack) do
			local apad_w = wnd.margin.l + wnd.margin.r
			local apad_h = wnd.margin.t + wnd.margin.b

			local wnd_y = (i - 1) * left_stack_h + wnd.margin.t + gap / 2 + (i - 1) * gap + gap_top

			wnd:move((VRESW - master_area_w) / 2 - stack_area_w - gap + gap_left + wnd.margin.l + gap / 2, wnd_y)
			wnd:resize(stack_area_w - gap_left - apad_w - gap, left_stack_h - apad_h - gap)
	 end

	 -- Right Stack
	 for i, wnd in ipairs(right_stack) do
			local bpad_w = wnd.margin.l + wnd.margin.r
			local bpad_h = wnd.margin.t + wnd.margin.b

			local wnd_y = (i - 1) * right_stack_h + wnd.margin.t + gap / 2 + (i - 1) * gap + gap_top

			wnd:move((VRESW + master_area_w) / 2 + gap + wnd.margin.l + gap / 2, wnd_y)
			wnd:resize(stack_area_w - gap_right - bpad_w - gap, right_stack_h - bpad_h - gap)
	 end
end
return arrange_master_middle_stack
