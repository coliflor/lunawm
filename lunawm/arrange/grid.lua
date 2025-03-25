local function arrange_grid(tag)
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

	 local cols = math.ceil(math.sqrt(n))
	 local rows = math.ceil(n / cols)

	 local tile_width = (VRESW - gap_left - gap_right) / cols
	 local tile_height = (VRESH - gap_top - gap_bottom) / rows

	 local index = 1
	 for col = 1, cols do
			local col_windows = {}
			for _ = 1, rows do
				 if index <= n then
						table.insert(col_windows, visible_windows[index])
						index = index + 1
				 end
			end

			local col_n = #col_windows
			local col_index = 1
			local current_y = gap_top

			for _ = 1, rows do
				 if col_index <= col_n then
						local wnd = col_windows[col_index]
						local pad_w = wnd.margin.l + wnd.margin.r
						local pad_h = wnd.margin.t + wnd.margin.b

						local x = (col - 1) * tile_width + wnd.margin.l + gap / 2 + gap_left

						if col_index == col_n then
							 -- Last window in column: expand to fill remaining height if needed
							 local remaining_height = VRESH - gap_top - current_y
							 if remaining_height > tile_height then
									wnd:move(x, current_y + wnd.margin.t + gap / 2)
									wnd:resize(tile_width - pad_w - gap, remaining_height - pad_h - gap)
							 else
									wnd:move(x, current_y + wnd.margin.t + gap / 2)
									wnd:resize(tile_width - pad_w - gap, tile_height - pad_h - gap)
							 end
						else
							 -- Regular window: use row-based tile height
							 wnd:move(x, current_y + wnd.margin.t + gap / 2)
							 wnd:resize(tile_width - pad_w - gap, tile_height - pad_h - gap)
							 current_y = current_y + tile_height
						end

						col_index = col_index + 1
				 end
			end
	 end
end

return arrange_grid
