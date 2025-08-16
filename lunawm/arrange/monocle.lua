local function arrange_monocle(tag)
	 local gap = wm.cfg.window_gap or 5
	 local gap_top = wm.cfg.window_gap_top or 0
	 local gap_bottom = wm.cfg.window_gap_bottom or 0
	 local gap_left = wm.cfg.window_gap_left or 0
	 local gap_right = wm.cfg.window_gap_right or 0

	 local visible_windows = {}
	 local statusbar_wnd = nil
	 local statusbar_height = wm.cfg.statusbar_height

	 for _, wnd in ipairs(tag) do
			if not wnd.tags then
				 wnd.tags = {}
			end

			if wnd.is_statusbar then
				 statusbar_wnd = wnd
			elseif wnd.tags[wm.current_tag] and wnd.tags[wm.current_tag].force_size == true then
				 table.insert(visible_windows, wnd)
			end
	 end

	 -- Handle the status bar separately if it exists
	 if statusbar_wnd then
			statusbar_wnd:move(0, 0)
			statusbar_wnd:resize(VRESW, statusbar_height)
			gap_top = gap_top + statusbar_height
	 end

	 local n = #visible_windows

	 for i = 1, n do
			local wnd = visible_windows[i]
			local pad_w = wnd.margin.l + wnd.margin.r
			local pad_h = wnd.margin.t + wnd.margin.b

			local usable_width = VRESW - gap_left - gap_right
			local usable_height = VRESH - gap_top - gap_bottom

			local wnd_y = wnd.margin.t + gap / 2 + gap_top

			wnd:move(wnd.margin.l + gap / 2 + gap_left, wnd_y)
			wnd:resize(usable_width - pad_w - gap, usable_height - pad_h - gap)
	 end
end

return arrange_monocle
