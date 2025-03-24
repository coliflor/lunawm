local function arrange_master_stack(tag)
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

			if wnd.tags[wm.current_tag] and wnd.tags[wm.current_tag].force_size == true then
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

	 local master_ratio = wm.tags[wm.current_tag].master_ratio or 0.5

	 local master_area_w = VRESW * master_ratio - gap_left - gap_right
	 local master_area_h = VRESH - gap_top - gap_bottom
	 local stack_area_x = master_area_w + gap_left
	 local stack_area_w = VRESW - master_area_w - gap_left - gap_right
	 local stack_area_h = VRESH - gap_top - gap_bottom

	 -- Master window (n > 1)
	 local master = visible_windows[1]
	 local pad_w = master.margin.l + master.margin.r
	 local pad_h = master.margin.t + master.margin.b

	 local master_y = master.margin.t + gap / 2 + gap_top

	 master:move(master.margin.l + gap / 2 + gap_left, master_y)
	 master:resize(master_area_w - pad_w - gap, master_area_h - pad_h - gap)

	 -- Stack windows (n > 1)
	 local stack_h = (stack_area_h - (n - 2) * gap) / (n - 1)
	 for i = 2, n do
			local wnd = visible_windows[i]
			local apad_w = wnd.margin.l + wnd.margin.r
			local apad_h = wnd.margin.t + wnd.margin.b

			local wnd_y = (i - 2) * stack_h + wnd.margin.t + gap / 2 + (i - 2) * gap + gap_top

			wnd:move(stack_area_x + wnd.margin.l + gap / 2, wnd_y)
			wnd:resize(stack_area_w - apad_w - gap, stack_h - apad_h - gap)
	 end
end

return arrange_master_stack
