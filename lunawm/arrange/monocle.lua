local function arrange_monocle(tag)
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

	 for i = 1, n do
			local wnd = visible_windows[i]
			local pad_w = wnd.margin.l + wnd.margin.r
			local pad_h = wnd.margin.t + wnd.margin.b

			local wnd_y = wnd.margin.t + gap / 2 + gap_top

			wnd:move(wnd.margin.l + gap / 2 + gap_left, wnd_y)
			wnd:resize(VRESW - pad_w - gap - gap_left - gap_right, VRESH - pad_h - gap - gap_top - gap_bottom)
	 end
end

return arrange_monocle
