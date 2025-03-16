local function arrange_grid(tag)
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

	 local cols = math.ceil(math.sqrt(n))
	 local rows = math.ceil(n / cols)

	 local tile_width = VRESW / cols
	 local tile_height = (VRESH - statusbar_height) / rows

	 local index = 1
	 for row = 1, rows do
			for col = 1, cols do
				 if index <= n then
						local wnd = visible_windows[index]
						local pad_w = wnd.margin.l + wnd.margin.r
						local pad_h = wnd.margin.t + wnd.margin.b

						local x = (col - 1) * tile_width + wnd.margin.l + gap / 2
						local y = (row - 1) * tile_height + wnd.margin.t + gap / 2

						if statusbar_position == "top" then
							 y = y + statusbar_height
						end

						wnd:move(x, y)
						wnd:resize(tile_width - pad_w - gap, tile_height - pad_h - gap)

						index = index + 1
				 end
			end
	 end
end

return arrange_grid
