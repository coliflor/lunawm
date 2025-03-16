local function arrange_monocle(tag)
	 local gap = wm.cfg.window_gap or 5
	 local statusbar_height = wm.cfg.statusbar_height or 20
	 local statusbar_position = wm.cfg.statusbar_position or "bottom"

	 local visible_windows = {}
	 for _, wnd in ipairs(tag) do
			if wnd.tags[wm.current_tag].force_size == true then
				 table.insert(visible_windows, wnd)
			end
	 end

	 local n = #visible_windows

	 for i = 1, n do
			local wnd = visible_windows[i]
			local pad_w = wnd.margin.l + wnd.margin.r
			local pad_h = wnd.margin.t + wnd.margin.b

			local wnd_y = wnd.margin.t + gap / 2
			if statusbar_position == "top" then
				 wnd_y = wnd_y + statusbar_height
			end

			wnd:move(wnd.margin.l + gap / 2, wnd_y)
			wnd:resize(VRESW - pad_w - gap, VRESH - statusbar_height - pad_h - gap)
	 end
end

return arrange_monocle
