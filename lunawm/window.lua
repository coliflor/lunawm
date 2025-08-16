local window= {}
local dirtbl = {"l", "r", "t", "b"}
local wndlist = {}
local hidden = {}

-- ----------------------------------------------------
--  helper functions for window spawn
-- ----------------------------------------------------
local defevhs = {}

local function cursor_handler(wnd, source, status)
	 if (status.kind == "terminated") then
			delete_image(source)
			wnd.mouse_cursor = nil
			local mx, my = mouse_xy()
			if (image_hit(wnd.canvas, mx, my)) then
				 wnd:over()
			end
			-- elseif status.kind == "resized" then
	 end
end

local function clipboard_handler(wnd, source, status)
	 if (status.kind == "message") then
			if (not wnd.multipart) then
				 wnd.multipart = {}
			end
			table.insert(wnd.multipart, status.message)
			if (not status.multipart) then
				 wnd.clipboard_message = table.concat(wnd.multipart, "")
				 wm.CLIPBOARD_MESSAGE = wnd.clipboard_message
				 wnd.multipart = {}
			end
	 elseif (status.kind == "terminated") then
			delete_image(source)
	 end
end

defevhs["resized"] = function(wnd, source, status)
	 wnd.flip_y = status.origo_ll

	 if (wnd.target == source) then
			if (wnd.tags[wm.current_tag].force_size) then
				 local current_tag = wm.current_tag
				 if wnd.tags[current_tag] then
						wnd:resize(wnd.tags[current_tag].width, wnd.tags[current_tag].height)
				 end
			else
				 wnd:resize(status.width, status.height)
			end
			wnd:update_tprops()
	 end
end

defevhs["terminated"] =
	 function(wnd, source, _)
			wnd:lost(source)
	 end

defevhs["ident"] =
	 function(wnd, _, status)
			wnd.ident = status.message
	 end

defevhs["segment_request"] =
	 function(wnd, _, stat)
			if (stat.segkind == "clipboard") then
				 wnd.clipboard_in = accept_target(
						function(src, stat_two)
							 clipboard_handler(wnd, src, stat_two);
				 end);
				 link_image(wnd.clipboard_in, wnd.anchor);
			elseif (stat.segkind == "cursor") then
				 local new = accept_target(function(src, stat_two)
							 cursor_handler(wnd, src, stat_two)
				 end)
				 if (valid_vid(new)) then
						link_image(new, wnd.anchor)
						wnd.mouse_cursor = new
						local mx, my = mouse_xy()
						if (image_hit(wnd.canvas, mx, my)) then
							 wnd:over()
						end
				 end
			end
	 end

local function group_handler(source, status)
	 local wnd = wm.windows[source]
	 if (wnd and defevhs[status.kind]) then
			defevhs[status.kind](wnd, source, status)
	 end
end

local function send_type_data(source, segkind)
	 local dstfont_sz = wm.cfg.default_font_sz
	 local dstfont = wm.cfg.default_font

	 if (segkind == "terminal" or segkind == "tui") then
			dstfont = wm.cfg.terminal_font
			dstfont_sz = wm.cfg.terminal_font_sz
	 end

	 for i,v in ipairs(dstfont) do
			target_fonthint(source, v, dstfont_sz, wm.cfg.terminal_hint, i > 1)
	 end
end

local function setup_wnd(vid, aid, opts)
	 if (not valid_vid(vid, TYPE_FRAMESERVER)) then
			return
	 end

	 local wnd = window.new_window(vid, aid, opts) -- Get the window object returned by new_window
	 target_displayhint(vid, opts.w, opts.h, TD_HINT_IGNORE, {ppcm = VPPCM, anchor = wnd.anchor}) -- Pass the anchor
	 return wnd
end

window.client_event_handler = function(source, status)

	 if status.kind == "terminated" then
			delete_image(source)
			-- elseif status.kind == "resized" then
			--resize_image(source, status.width, status.height)
	 elseif status.kind == "connected" then
			target_alloc(wm.cfg.conn_point, wm.client_event_handler)
			-- elseif status.kind == "registered" then
	 elseif status.kind == "preroll" then
			if status.segkind == "icon" then
				 local proptbl = {
						x = 0,
						y = 0,
						w = VRESW,
						h = 32,
						autocrop = true,
						no_decor = true,
				 }

				 local wnd = setup_wnd(source, status.source_audio, proptbl)

				 table.insert(wm.tags[wm.current_tag], wnd) -- Add window directly to tags

				 -- Ensure wnd.tags[tag_index] exists before assigning force_size
				 if not wnd.tags[wm.current_tag] then
						wnd.tags[wm.current_tag] = {}
				 end

				 wnd.is_statusbar = true

				 window.arrange() -- Call arrange after adding the window

				 target_updatehandler(source, group_handler)
				 send_type_data(source, "statusbar")

				 wnd:select()
			else
				 local proptbl = {
						x = 0,
						y = 0,
						w = 32,
						h = 32,
						autocrop = true,
				 }

				 local wnd = setup_wnd(source, status.source_audio, proptbl)

				 table.insert(wm.tags[wm.current_tag], wnd) -- Add window directly to tags

				 -- Ensure wnd.tags[tag_index] exists before assigning force_size
				 if not wnd.tags[wm.current_tag] then
						wnd.tags[wm.current_tag] = {}
				 end

				 wnd.tags[wm.current_tag].force_size = true

				 window.arrange() -- Call arrange after adding the window

				 target_updatehandler(source, group_handler)
				 send_type_data(source, "terminal")

				 wnd:select()
			end

			--elseif status.kind == "segment_request" and status.segkind == "clipboard" then
	 end
end

window.terminal = function()
	 local arg = wm.cfg.terminal_cfg .. "env=ARCAN_CONNPATH=" .. wm.cfg.conn_point

	 launch_avfeed(arg, "terminal", function(source, status)
										if (status.kind == "preroll") then
											 wm.client_event_handler(source, status)
										end
	 end)
end

-- ----------------------------------------------------
-- Window Managment
-- ----------------------------------------------------

local function get_first_tag_with_data(wnd)
	 for tag,_ in pairs(wnd.tags) do
			if wnd.tags[tag] and wnd.tags[tag].width then
				 return tag
			end
	 end
	 return nil
end

local function reorder_windows()
	 local stacked_windows = {}
	 local non_stacked_windows = {}

	 -- Separate windows into stacked and non-stacked
	 for _, wnd in ipairs(wndlist) do
			if wnd.tags[wm.current_tag].force_size then
				 table.insert(stacked_windows, wnd)
			else
				 table.insert(non_stacked_windows, wnd)
			end
	 end

	 -- Reorder stacked windows first
	 local order = 10
	 for _, wnd in ipairs(stacked_windows) do
			order_image(wnd.anchor, order)
			order = order + 10
	 end

	 -- Reorder non-stacked windows after stacked windows
	 for _, wnd in ipairs(non_stacked_windows) do
			order_image(wnd.anchor, order)
			order = order + 10
	 end
end

local function window_decor_resize(wnd, neww, newh)
	 local bw = wm.cfg.border_width

	 if (not wnd.decor.l) then return end
	 resize_image(wnd.decor.l, bw, newh)
	 resize_image(wnd.decor.r, bw, newh)
	 resize_image(wnd.decor.t, neww + bw + bw, bw)
	 resize_image(wnd.decor.b, neww + bw + bw, bw)
	 move_image(wnd.decor.l, -bw, 0)
	 move_image(wnd.decor.b, -bw, 0)
	 move_image(wnd.decor.t, -bw, -bw)
end

local function window_bordercolor(wnd, r, g, b)
	 for _,v in ipairs(dirtbl) do
			if (not wnd.decor[v]) then return end
			image_color(wnd.decor[v], r, g, b)
	 end
end

--
-- different cases:
-- 1  2  3
-- 4     5
-- 6  7  8
--
local function resize_move(ctx, dx, dy, move, inx, iny)
	 local wnd = ctx.wnd
	 if (not wnd.anchor) then
			return
	 end
	 local props = image_surface_properties(wnd.anchor)

	 -- setup two accumulators
	 if (not ctx.state) then
			ctx.state = {dx, dy}
	 else
			ctx.state[1] = ctx.state[1] + dx
			ctx.state[2] = ctx.state[2] + dy
	 end

	 local rzx = 0
	 local rzy = 0

	 -- if the absolute accumulation exceeds inertia, resize that many steps
	 if (math.abs(ctx.state[1]) >= inx) then
			rzx = math.floor(ctx.state[1] / inx)
			ctx.state[1] = ctx.state[1] - (rzx * inx)
	 end

	 if (math.abs(ctx.state[2]) >= iny) then
			rzy = math.floor(ctx.state[2] / iny)
			ctx.state[2] = ctx.state[2] - (rzy * iny)
	 end

	 local current_tag = wm.current_tag
	 local tag_data = wnd.tags[current_tag]

	 if (not tag_data) then
			tag_data = wnd.tags[get_first_tag_with_data(wnd)]
	 end

	 local neww = tag_data.width + rzx * inx
	 local newh = tag_data.height + rzy * iny
	 neww = neww < wnd.min_w and wnd.min_w or neww
	 newh = newh < wnd.min_h and wnd.min_h or newh

	 if (neww == tag_data.width and newh == tag_data.height) then
			return
	 end

	 local nx = props.x
	 local ny = props.y

	 if (move == 1) then
			nx = nx + (tag_data.width - neww)
			ny = ny + (tag_data.height - newh)
	 elseif (move == 2) then
			ny = ny + (tag_data.height - newh)
	 elseif (move == 3) then
			nx = nx + (tag_data.width - neww)
	 elseif (move == 4) then
			ny = ny + (tag_data.height - newh)
	 end

	 -- this will look "jittery" if target is slow to resize or we
	 -- don't autocrop
	 if (wnd.autocrop or wnd.tags[wm.current_tag].force_size or not
			 valid_vid(wnd.target, TYPE_FRAMESERVER)) then
			wnd:resize(neww, newh)
			move_image(wnd.anchor, nx, ny)
	 else
			target_displayhint(wnd.target, neww, newh)
			wnd.defer_x = nx
			wnd.defer_y = ny
	 end
end

local function window_update_tprops(wnd)
	 image_set_txcos_default(wnd.canvas, wnd.flip_y)

	 if (wnd.autocrop) then
			local ip = image_storage_properties(wnd.canvas)

			local current_tag = wm.current_tag
			local tag_data = wnd.tags[current_tag]

			if (not tag_data) then
				 tag_data = wnd.tags[get_first_tag_with_data(wnd)]
			end

			image_scale_txcos(wnd.canvas,
												tag_data.width / ip.width, tag_data.height / ip.height)
	 end
end

-- assumption: cursor is on [vid]
local function set_trigger_point(ctx, vid)
	 if (ctx.wnd.drag_track) then
			return
	 end

	 -- track the drag- point so we can warp the mouse on regions
	 -- with high drag- inertia or delayed synch
	 local props = image_surface_resolve_properties(vid)
	 local mx,my = mouse_xy()
	 local rel_x = (mx - props.x) / props.width
	 local rel_y = (my - props.y) / props.height
	 rel_x = rel_x < 0 and 0 or rel_x
	 rel_x = rel_x > 1 and 1 or rel_x
	 rel_y = rel_y < 0 and 0 or rel_y
	 rel_y = rel_y > 1 and 1 or rel_y

	 ctx.wnd.drag_track = {
			vid = vid,
			start_x = mx,
			start_y = my,
			rel_x = rel_x,
			rel_y = rel_y
	 }
end

local function decor_v_drag(ctx, vid, dx, dy)
	 if (ctx.wnd ~= wm.window) then
			return
	 end

	 local inx = wm.cfg.drag_resize_inertia
	 local iny = wm.cfg.drag_resize_inertia
	 set_trigger_point(ctx, vid)

	 ctx.wnd:select()
	 if (ctx.wnd.inertia) then
			inx = ctx.wnd.inertia[1]
			iny = ctx.wnd.inertia[2]
	 end

	 local uln = ctx.ul_near
	 if (ctx.diag == -1) then
			if (uln) then
				 resize_move(ctx, -dx, -dy, 1, inx, iny)
			else
				 resize_move(ctx, dx,  -dy, 4, inx, iny)
			end
	 elseif (ctx.diag == 0) then
			if (uln) then
				 resize_move(ctx, -dx, 0, 3, inx, iny)
			else
				 resize_move(ctx,  dx, 0, 0, inx, iny)
			end
	 elseif (ctx.diag == 1) then
			if (uln) then
				 resize_move(ctx, -dx, dy, 3, inx, iny)
			else
				 resize_move(ctx, dx, dy, 0, inx, iny)
			end
			-- else
			-- means the _over event didn't fire before drag, shouldn't happen
	 end

	 if ctx.wnd.tags[wm.current_tag].force_size == true then
			ctx.wnd.tags[wm.current_tag].force_size = false
			wm.arrange()
	 end
end

local function decor_drop(ctx)
	 ctx.state = nil
	 if (ctx.wnd.drag_track) then
			if (valid_vid(ctx.wnd.drag_track.hint)) then
				 delete_image(ctx.wnd.drag_track.hint)
			end
			ctx.wnd.drag_track = nil
	 end
end

local function decor_h_drag(ctx, vid, dx, dy)
	 if (ctx.wnd ~= wm.window) then
			return
	 end

	 -- cases: 1,2,3 - 6,7,8
	 local inx = wm.cfg.drag_resize_inertia
	 local iny = wm.cfg.drag_resize_inertia
	 set_trigger_point(ctx, vid)
	 ctx.wnd:select()
	 if (ctx.wnd.inertia) then
			inx = ctx.wnd.inertia[1]
			iny = ctx.wnd.inertia[2]
	 end

	 local uln = ctx.ul_near
	 if (ctx.diag == -1) then
			if (ctx.ul_near) then
				 resize_move(ctx, -dx, -dy, 1, inx, iny)
			else
				 resize_move(ctx, -dx,  dy, 3, inx, iny)
			end
	 elseif (ctx.diag == 0) then
			if (uln) then
				 resize_move(ctx, 0,-dy, 2, inx, iny)
			else
				 resize_move(ctx, 0, dy, 0, inx, iny)
			end
	 elseif (ctx.diag == 1) then
			if (uln) then
				 resize_move(ctx, dx, -dy, 4, inx, iny)
			else
				 resize_move(ctx, dx, dy, 0, inx, iny)
			end
	 end

	 if ctx.wnd.tags[wm.current_tag].force_size == true then
			ctx.wnd.tags[wm.current_tag].force_size = false
			wm.arrange()
	 end
end

local function decor_v_over(ctx, vid, _, y)
	 if (ctx.wnd ~= wm.window) then
			ctx.wnd:select()
			return
	 end

	 local props = image_surface_resolve_properties(vid)
	 local ly = y - props.y
	 local margin = props.height * 0.1
	 if (ly < margin) then
			ctx.diag = -1
			mouse_switch_cursor(ctx.ul_near and "rz_diag_r" or "rz_diag_l")
	 elseif (ly > props.height - margin) then
			ctx.diag = 1
			mouse_switch_cursor(ctx.ul_near and "rz_diag_l" or "rz_diag_r")
	 else
			ctx.diag = 0
			mouse_switch_cursor(ctx.ul_near and "rz_left" or "rz_right")
	 end
end

local function decor_h_over(ctx, vid, x, _)
	 if (ctx.wnd ~= wm.window) then
			ctx.wnd:select()
			return
	 end

	 local props = image_surface_resolve_properties(vid)
	 local lx = x - props.x
	 local margin = props.width * 0.1
	 if (lx < margin) then
			ctx.diag = -1
			mouse_switch_cursor(ctx.ul_near and "rz_diag_r" or "rz_diag_l")
	 elseif (lx > props.width - margin) then
			mouse_switch_cursor(ctx.ul_near and "rz_diag_l" or "rz_diag_r")
			ctx.diag = 1
	 else
			ctx.diag = 0
			mouse_switch_cursor(ctx.ul_near and "rz_up" or "rz_down")
	 end
end

local function decor_sel(ctx)
	 ctx.wnd:select()
end

local function decor_reset()
	 mouse_switch_cursor("def", true)
end

-- build the decorations: tttt
--                        l  r
--                        bbbb and anchor for easier resize
local function build_decorations(wnd, opts)
	 local bw = wm.cfg.border_width

	 if bw == 0 or opts.no_decor == true or wnd.is_statusbar then
			-- Remove old decorations
			if wnd.decor then
				 for _, decor in pairs(wnd.decor) do
						if valid_vid(decor) then
							 delete_image(decor)
						end
				 end
				 wnd.decor = {}
			end

			-- Resize the window to its original size (without borders)
			if wnd.tag_dimensions and wnd.tag_dimensions[wm.current_tag] then
				 local dims = wnd.tag_dimensions[wm.current_tag]
				 wnd:resize(dims.width - wnd.margin.l - wnd.margin.r, dims.height - wnd.margin.t - wnd.margin.b)
			end

			-- Update margin values
			wnd.margin = { t = 0, l = 0, r = 0, b = 0 }

			return
	 end

	 for _, v in ipairs(dirtbl) do
			wnd.decor[v] = color_surface(1, 1, 0, 0, 0)
			image_inherit_order(wnd.decor[v], true)
			blend_image(wnd.decor[v], wm.cfg.border_alpha)
			wnd.margin[v] = bw
	 end

	 link_image(wnd.decor.r, wnd.anchor, ANCHOR_UR)
	 link_image(wnd.decor.l, wnd.anchor, ANCHOR_UL)
	 link_image(wnd.decor.b, wnd.anchor, ANCHOR_LL)
	 link_image(wnd.decor.t, wnd.anchor)

	 if (not opts.no_mouse) then
			wnd.decor_mh.r = {
				 wnd = wnd,
				 name = "decor_r",
				 own = wnd.decor.r,
				 ul_near = false,
				 motion = decor_v_over,
				 -- drag = decor_v_drag,
				 click = decor_sel,
				 drop = decor_drop,
				 out = decor_reset
			}
			wnd.decor_mh.t = {
				 wnd = wnd,
				 name = "decor_t",
				 own = wnd.decor.t,
				 ul_near = true,
				 motion = decor_h_over,
				 -- drag = decor_h_drag,
				 click = decor_sel,
				 out = decor_reset,
				 drop = decor_drop
			}
			wnd.decor_mh.l = {
				 wnd = wnd,
				 name = "decor_l",
				 own = wnd.decor.l,
				 ul_near = true,
				 motion = decor_v_over,
				 -- drag = decor_v_drag,
				 click = decor_sel,
				 out = decor_reset,
				 drop = decor_drop
			}
			wnd.decor_mh.b = {
				 wnd = wnd,
				 name = "decor_b",
				 own = wnd.decor.b,
				 ul_near = false,
				 motion = decor_h_over,
				 drag = decor_h_drag,
				 click = decor_sel,
				 drop = decor_drop,
				 out = decor_reset
			}

			for _ , v in ipairs(dirtbl) do
				 mouse_addlistener(wnd.decor_mh[v], {
															"drag", "hover", "click", "rclick", "drop", "motion", "out"
				 })
			end
	 end

	 local current_tag = wm.current_tag
	 local tag_data = wnd.tags[current_tag]

	 if (not tag_data) then
			tag_data = wnd.tags[get_first_tag_with_data(wnd)]
	 end

	 window_decor_resize(wnd, tag_data.width, tag_data.height)
end

window.rebuild_all_decorations = function()
	 for _, wnd in ipairs(wndlist) do
			-- Assuming 'opts' is available or can be reconstructed
			build_decorations(wnd, { no_decor = true })
	 end
end

local function window_resize(wnd, neww, newh)
	 if wnd.is_statusbar then
			neww = VRESW
			newh = wm.cfg.statusbar_height
	 end

	 local pad_v = wnd.margin.t - wnd.margin.b
	 local pad_h = wnd.margin.l - wnd.margin.r

	 -- Ensure neww and newh are not negative before clamping
	 neww = math.max(0, neww)
	 newh = math.max(0, newh)

	 neww = (neww > VRESW - pad_h) and (VRESW - pad_h) or neww
	 newh = (newh > VRESH - pad_v) and (VRESH - pad_v) or newh

	 -- Ensure neww and newh are not negative after clamping
	 neww = math.max(0, neww)
	 newh = math.max(0, newh)

	 resize_image(wnd.canvas, neww, newh)
	 resize_image(wnd.anchor, neww, newh)
	 window_decor_resize(wnd, neww, newh)

	 local current_tag = wm.current_tag

	 target_displayhint(wnd.target, neww, newh)

	 if (wnd.defer_x) then
			move_image(wnd.anchor, wnd.defer_x, wnd.defer_y)
			if (wnd.drag_track and valid_vid(wnd.drag_track.vid)) then
				 local props = image_surface_resolve_properties(wnd.drag_track.vid)
				 wnd.drag_track.start_x = props.x + props.width * wnd.drag_track.rel_x
				 wnd.drag_track.start_y = props.y + props.height * wnd.drag_track.rel_y
			end
			wnd.defer_x = nil
	 end

	 if (wnd.autocrop) then
			local ip = image_storage_properties(wnd.canvas)
			image_set_txcos_default(wnd.canvas, wnd.origio_ll)
			image_scale_txcos(wnd.canvas, neww / ip.width, newh / ip.height)
	 end

	 -- Update tag-specific dimensions
	 if wnd.tags[current_tag] then
			wnd.tags[current_tag].width = neww
			wnd.tags[current_tag].height = newh
	 else
			-- If tag data doesn't exist, create it
			wnd.tags[current_tag] = {
				 width = neww,
				 height = newh,
				 x = wnd.tags[get_first_tag_with_data(wnd)].x,
				 y = wnd.tags[get_first_tag_with_data(wnd)].y,
			}
	 end

	 for _,v in ipairs(wnd.event_hooks) do
			v(wnd, "resize")
	 end
end

local function window_select(wnd)
	 if (wm.window) then
			if (wm.window ~= wnd) then
				 if (type(wm.window.deselect) == "function") then
						wm.window:deselect()
				 end
			else
				 return true
			end
	 end

	 local oldi
	 for i,v in ipairs(wndlist) do
			if (v == wnd) then
				 oldi = i
				 table.remove(wndlist, i)
				 break
			end
	 end
	 table.insert(wndlist, wnd)

	 wm.window = wnd
	 if (valid_vid(wnd.target)) then
			wnd.dispmask = (bit.band(wnd.dispmask, bit.bnot(TD_HINT_UNFOCUSED)))
			target_displayhint(wnd.target, 0, 0, wnd.dispmask)
	 end
	 wnd:border_color(unpack(wm.cfg.active_color))
	 reorder_windows()

	 for _,v in ipairs(wnd.event_hooks) do
			v(wnd, "select", oldi)
	 end
	 return true
end

local function window_deselect(wnd)
	 if (valid_vid(wnd.target)) then
			wnd.dispmask = bit.bor(wnd.dispmask, TD_HINT_UNFOCUSED)
			target_displayhint(wnd.target, 0, 0, wnd.dispmask)
	 end
	 wnd:border_color(unpack(wm.cfg.inactive_color))
	 if (wm.window == wnd) then
			wm.window = nil
	 end

	 for _,v in ipairs(wnd.event_hooks) do
			v(wnd, "deselect")
	 end
end

local function window_lost(wnd, _)
	 wnd:destroy()
end

local function window_hide(wnd)
	 wnd:deselect()
	 hide_image(wnd.anchor)
	 for _,v in ipairs(wnd.event_hooks) do
			v(wnd, "hide")
	 end

	 table.insert(hidden, wnd)
	 hidden[wnd] = true
end

local function window_show(wnd)
	 for k, v in ipairs(hidden) do
			if (v == wnd) then
				 wnd:select()

				 local current_tag = wm.current_tag
				 local tag_data = wnd.tags[current_tag]

				 if (not tag_data) then
						tag_data = wnd.tags[get_first_tag_with_data(wnd)]
				 end

				 table.remove(hidden, k)
				 hidden[wnd] = nil
				 show_image(wnd.anchor)
				 wnd:resize(tag_data.width, tag_data.height)
				 wnd:move(tag_data.x, tag_data.y)

				 for _, h in ipairs(wnd.event_hooks) do
						h(wnd, "show")
				 end
				 return
			end
	 end
end

local function window_destroy(wnd)
	 image_surface_resolve_properties(wnd.canvas)
	 if (wm.window == wnd) then
			wm.window = nil
	 end

	 local mx, my = mouse_xy()
	 if (image_hit(wnd.canvas, mx, my)) then
			mouse_switch_cursor("def", true)
			mouse_show()
	 end

	 -- drop global tracking
	 for i = #wndlist, 1, -1 do
			if (wndlist[i] == wnd) then
				 table.remove(wndlist, i)
			end
	 end

	 for k, v in pairs(wm.windows) do
			if (v == wnd) then
				 wm.windows[k] = nil
			end
	 end

	 -- might come from an event on a hidden window
	 for k, v in ipairs(hidden) do
			if (v == wnd) then
				 table.remove(hidden, k)
				 hidden[wnd] = nil
				 break
			end
	 end

	 -- remove mouse handlers
	 for _, v in pairs(wnd.decor_mh) do
			mouse_droplistener(v)
	 end
	 mouse_droplistener(wnd)

	 for _, v in ipairs(wnd.event_hooks) do
			v(wnd, "destroy")
	 end

	 -- anchor will just cascade delete everything.
	 delete_image(wnd.anchor)

	 -- but reset the table to identify any dangling refs.
	 for k, _ in pairs(wnd) do
			wnd[k] = nil
	 end
	 wnd.dead = true

	 -- find something else to select
	 if (not wm.window) then
			-- Select the next window in line
			if #wndlist > 0 then
				 wndlist[#wndlist]:select()
			end
	 end

	 -- Remove window from tag
	 for _, tag in pairs(wm.tags) do
			for j, c in ipairs(tag) do
				 if c == wnd then
						table.remove(tag, j)
						break
				 end
			end
	 end

	 window.arrange()
end

local function window_move(wnd, x, y)
	 if wnd.is_statusbar then
			return
	 end

	 move_image(wnd.anchor, x, y)

	 -- Update tag-specific position
	 local current_tag = wm.current_tag
	 if wnd.tags[current_tag] then
			wnd.tags[current_tag].x = x
			wnd.tags[current_tag].y = y
	 else
			-- If tag data doesn't exist, create it.
			wnd.tags[current_tag] = {
				 x = x,
				 y = y,
				 width = wnd.tags[get_first_tag_with_data(wnd)].width,
				 height = wnd.tags[get_first_tag_with_data(wnd)].height,
			}
	 end
end

local function window_maximize(wnd, dir)
	 -- revert
	 if (wnd.maximized) then
			wnd:move(wnd.maximized.x, wnd.maximized.y)
			wnd:resize(wnd.maximized.w, wnd.maximized.h)
			wnd.maximized = nil
			return
	 end

	 -- let move/resize account for decorations
	 local props = image_surface_resolve_properties(wnd.anchor)

	 local current_tag = wm.current_tag
	 local tag_data = wnd.tags[current_tag]

	 if (not tag_data) then
			tag_data = wnd.tags[get_first_tag_with_data(wnd)]
	 end

	 wnd.maximized = {
			x = props.x, y = props.y,
			w = tag_data.width, h = tag_data.height
	 }
	 local pad_w = wnd.margin.l + wnd.margin.r
	 local pad_h = wnd.margin.t + wnd.margin.b
	 if (dir == "f") then
			wnd:resize(VRESW - pad_w, VRESH - pad_h)
			wnd:move(wnd.margin.l, wnd.margin.t)
	 elseif (dir == "l") then
			wnd:move(wnd.margin.l, wnd.margin.t)
			wnd:resize(math.floor((0.5 * VRESW) - pad_w), VRESH - pad_h)
	 elseif (dir == "r") then
			wnd:resize(math.floor((0.5 * VRESW) - pad_w), VRESH - pad_h)
			wnd:move(math.ceil(VRESW * 0.5)+ wnd.margin.l, wnd.margin.t)
	 elseif (dir == "t") then
			wnd:move(wnd.margin.l, wnd.margin.t)
			wnd:resize(VRESW - pad_w, math.floor((0.5 * VRESH) - pad_h))
	 elseif (dir == "b") then
			wnd:resize(VRESW - pad_w, math.floor((0.5 * VRESH) - pad_h))
			wnd:move(wnd.margin.l, math.ceil(VRESH * 0.5) + wnd.margin.t)
	 end
end

local function window_fullscreen(wnd, dir)
	 -- revert
	 if (wnd.maximized) then
			wnd:move(wnd.maximized.x, wnd.maximized.y)
			wnd:resize(wnd.maximized.w, wnd.maximized.h)
			wnd.maximized = nil
			return
	 end

	 -- let move/resize account for decorations
	 local props = image_surface_resolve_properties(wnd.anchor)

	 local current_tag = wm.current_tag
	 local tag_data = wnd.tags[current_tag]

	 if (not tag_data) then
			tag_data = wnd.tags[get_first_tag_with_data(wnd)]
	 end

	 wnd.maximized = {
			x = props.x, y = props.y,
			w = tag_data.width, h = tag_data.height
	 }

	 local pad_w = 0
	 local pad_h = 0

	 if (dir == "f") then
			wnd:resize(VRESW - pad_w, VRESH - pad_h)
			wnd:move(0, 0)
	 elseif (dir == "l") then
			wnd:move(0, 0)
			wnd:resize(math.floor(0.5 * VRESW), VRESH)
	 elseif (dir == "r") then
			wnd:resize(math.floor(0.5 * VRESW), VRESH)
			wnd:move(math.ceil(VRESW * 0.5), 0)
	 elseif (dir == "t") then
			wnd:move(0, 0)
			wnd:resize(VRESW, math.floor(0.5 * VRESH))
	 elseif (dir == "b") then
			wnd:resize(VRESW, math.floor(0.5 * VRESH))
			wnd:move(0, math.ceil(VRESH * 0.5))
	 end
end

local function step_sz(wnd)
	 local ssx = wnd.inertia and wnd.inertia[1] or wm.cfg.drag_resize_inertia
	 local ssy = wnd.inertia and wnd.inertia[2] or wm.cfg.drag_resize_inertia
	 return ssx, ssy
end

local function window_step_move(wnd, _, xd, yd)
	 local sx, sy = step_sz(wnd)
	 nudge_image(wnd.anchor, xd * sx, yd * sy)
end

local function window_step_sz(wnd, steps, xd, yd)
	 local sx, sy = step_sz(wnd)

	 local current_tag = wm.current_tag
	 local tag_data = wnd.tags[current_tag]

	 if (not tag_data) then
			tag_data = wnd.tags[get_first_tag_with_data(wnd)]
	 end

	 local neww = tag_data.width + steps * sx * xd
	 local newh = tag_data.height + steps * sy * yd
	 wnd:resize(neww, newh)
end

local function window_drag_move(wnd, x, y)
	 if wnd.is_statusbar then
			return
	 end

	 if (wnd.drag_data) then
			local dx = x - wnd.drag_data.start_x
			local dy = y - wnd.drag_data.start_y
			wnd:move(wnd.drag_data.wnd_x + dx, wnd.drag_data.wnd_y + dy)
	 end
end

local function window_drag_end(wnd)
	 wnd.drag_data = nil
end

local function window_convert_mouse_xy(wnd, x, y)
	 -- note, this should really take viewport into account (if provided), when
	 -- doing so, move this to be part of fsrv-resize and manual resize as this is
	 -- rather wasteful.

	 -- first, remap coordinate range (x, y are absolute)
	 local aprop = image_surface_resolve(wnd.canvas)
	 local locx = x - aprop.x
	 local locy = y - aprop.y

	 -- take server-side scaling into account
	 local res = {}
	 local sprop = image_storage_properties(
			valid_vid(wnd.external) and wnd.external or wnd.canvas)

	 if wnd.autocrop then
			aprop.width = sprop.width
			aprop.height = sprop.height
	 end

	 local sfx = sprop.width / aprop.width
	 local sfy = sprop.height / aprop.height
	 local lx = sfx * locx
	 local ly = sfy * locy

	 res[1] = lx
	 res[2] = 0
	 res[3] = ly
	 res[4] = 0

	 return res
end

local function window_mousemotion(ctx, _, x, y)

	 if (ctx.drag_data) then
			window_drag_move(ctx, x, y)
			return -- Prevent further processing
	 end

	 local outm = {
			kind = "analog",
			mouse = true,
			devid = 0,
			subid = 2,
			samples = window_convert_mouse_xy(ctx, x, y)
	 }
	 if (not valid_vid(ctx.target, TYPE_FRAMESERVER)) then
			return
	 end

	 target_input(ctx.target, outm)
end

local function window_drag_start(wnd, x, y)

	 if wnd.tags[wm.current_tag].force_size == true then
			wnd.tags[wm.current_tag].force_size = false
			window.arrange()
	 end

	 if (not wnd.drag_data) then
			wnd.drag_data = {
				 start_x = x,
				 start_y = y,
				 wnd_x = image_surface_resolve_properties(wnd.anchor).x,
				 wnd_y = image_surface_resolve_properties(wnd.anchor).y
			}
	 end
end

local function window_mousebutton(ctx, _, ind, act)

	 -- Select window on click (any button)
	 if act then -- If any button is pressed
			ctx:select()
	 end

	 if (act and ind == 1 and wm.mod_key_pressed) then -- Left click pressed and mod key pressed
			window_drag_start(ctx, mouse_xy())
			return -- Prevent further processing
	 end

	 if (not act and ind == 1 and ctx.drag_data) then
			window_drag_end(ctx)
			return -- Prevent further processing
	 end

	 -- Window swapping logic
	 if (act and ind == 2 and wm.mod_key_pressed) then -- Modkey + Left Click (ind == 2)
			if (wm.swap_window1 == nil) then
				 -- First window selection
				 wm.swap_window1 = ctx
			elseif (wm.swap_window1 ~= ctx) then
				 -- Second window selection and swap
				 local window1 = wm.swap_window1
				 local window2 = ctx

				 if window1 and window2 then
						-- Perform the swap
						local tag = wm.tags[wm.current_tag]

						if tag then
							 local index1 = nil
							 local index2 = nil

							 -- Find the indices of the windows in the tag
							 for i, wnd in ipairs(tag) do
									if wnd == window1 then
										 index1 = i
									elseif wnd == window2 then
										 index2 = i
									end
							 end

							 if index1 and index2 then
									-- Swap the windows in the tag
									tag[index1], tag[index2] = tag[index2], tag[index1]
									window.arrange() -- Re-arrange windows
							 end
						end
				 end

				 -- Reset swap state
				 wm.swap_window1 = nil
			else
				 wm.swap_window1 = nil
			end
			return -- Prevent further processing
	 end

	 if (act and ind == 3 and wm.mod_key_pressed) then
			if ctx.tags and ctx.tags[wm.current_tag] then
				 ctx.tags[wm.current_tag].force_size = not ctx.tags[wm.current_tag].force_size
				 wm.arrange() -- Re-arrange windows
			end
			return
	 end

	 if (ctx.mouse_btns and ctx.mouse_btns[ind] ~= act) then
			ctx.mouse_btns[ind] = act
			if (valid_vid(ctx.target, TYPE_FRAMESERVER)) then
				 target_input(ctx.target, {digital = true, mouse = true, devid = 0, subid = ind, active = act})
			end
	 end
end

local function window_mouseover(ctx)
	 if (ctx.wnd and ctx.wnd ~= wm.window) then -- Check if window exists and is not already focused
			ctx.wnd:select() -- Select the window on mouseover
	 end

	 if (ctx.mouse_cursor) then
			mouse_custom_cursor(ctx.mouse_cursor, true)
	 elseif (ctx.mouse_hidden) then
			mouse_hide()
	 else
			mouse_switch_cursor("def", true)
	 end
end

local function window_mouseout(ctx)
	 mouse_show()
	 mouse_switch_cursor("def", true)

	 if (not valid_vid(ctx.target, TYPE_FRAMESERVER)) then
			return
	 end

	 -- release any buttons that are held
	 for i,v in pairs(ctx.mouse_btns) do
			if (v) then
				 ctx.mouse_btns[i] = false
				 target_input(ctx.target,
											{digital = true, mouse = true, devid = 0, subid = i, active = false})
			end
	 end
end

local function window_paste(wnd, msg)
	 if (not wnd.clipboard_out) then
			if (not valid_vid(wnd.target, TYPE_FRAMESERVER)) then
				 return
			end
			local tgt_clip = define_nulltarget(wnd.target,
																				 function()
			end)
			if (not valid_vid(tgt_clip)) then
				 return
			end

			wnd.clipboard_out = tgt_clip
			link_image(wnd.clipboard_out, wnd.anchor)
	 end

	 -- slightly incorrect as target_input can come up short, the
	 -- real option is to have a background timer and continously flush
	 if (msg and string.len(msg) > 0) then
			target_input(wnd.clipboard_out, msg)
	 end
end

window.arrange = function()
	 local tag = wm.tags and wm.tags[wm.current_tag] or {}
	 local n = #tag

	 if n == 0 then return end

	 local layout_mode = wm.tags[wm.current_tag].layout_mode or wm.cfg.layout_mode

	 local arranger = wm.arrangers[layout_mode]

	 if arranger then
			arranger(tag)
	 else
			wm.arrangers.master_stack(tag) -- Default to master_stack if not found
	 end
end

window.set_layout_mode = function(mode)
	 wm.tags[wm.current_tag].layout_mode = mode
	 window.arrange() -- Re-arrange windows after changing layout
end

window.new_window = function(vid, aid, opts)
	 assert(opts and opts.x and opts.y and opts.w and opts.h)

	 -- create anchor to track and control position and ordering
	 local anchor = null_surface(opts.w, opts.h)
	 if (not valid_vid(anchor)) then
			return
	 end

	 blend_image(anchor, 1.0, wm.cfg.animation_speed)
	 move_image(anchor, opts.x, opts.y)
	 link_image(vid, anchor)
	 image_inherit_order(vid, true)
	 image_mask_set(anchor, MASK_UNPICKABLE)

	 -- fade in and resize
	 show_image(vid)
	 resize_image(vid, opts.w, opts.h)

	 local wnd = {
			name = "lunawm_window",
			anchor = anchor,
			canvas = vid,
			aid = aid,
			min_w = 32,
			min_h = 32,
			created = CLOCK,
			dispmask = 0, -- tracking display state
			event_hooks = {},
			title = "",
			ident = "",

			-- decorations
			no_decor = true,
			decor = {},
			decor_mh = {},
			margin = {t = 0, l = 0, r = 0, b = 0},

			-- input controls
			mscale = {},
			own = vid,
			mouse_btns = {},

			-- window maipulation
			build_decor  = build_decorations,
			resize = window_resize,
			move = window_move,
			select = window_select,
			deselect = window_deselect,
			destroy = window_destroy,
			hide = window_hide,
			show = window_show,
			lost = window_lost,
			border_color = window_bordercolor,
			step_move = window_step_move,
			step_sz = window_step_sz,
			motion = window_mousemotion,
			button = window_mousebutton,
			over = window_mouseover,
			out = window_mouseout,
			maximize = window_maximize,
			fullscreen = window_fullscreen,
			update_tprops = window_update_tprops,
			paste = window_paste,

			-- toggles
			autocrop = opts.autocrop,
			flip_y = opts.flip_y,

			tags = {},
			is_statusbar = false,
	 }

	 -- Initialize tags with default values
	 for i = 1, wm.cfg.num_tags do
			wnd.tags[i] = {
				 width = opts.w,
				 height = opts.h,
				 x = opts.x,
				 y = opts.y,
				 force_size = true,
				 layout_mode = wm.cfg.default_layout_mode,
				 master_ratio = wm.cfg.default_master_ratio,
			}
	 end

	 if (not opts.no_decor) then
			build_decorations(wnd, opts)
	 end

	 if (not opts.no_mouse) then
			mouse_addlistener(wnd, {"motion", "button", "over", "out"})
	 end

	 -- special treatment, vid might be a color target (popups, ...)
	 if (valid_vid(vid, TYPE_FRAMESERVER)) then
			local canvas = null_surface(opts.w, opts.h)
			link_image(canvas, wnd.anchor)
			image_inherit_order(canvas, true)
			show_image(canvas)
			image_sharestorage(vid, canvas)
			order_image(canvas, 1)
			wnd.own = canvas
			wnd.canvas = canvas
			wnd.target = vid
	 end

	 -- index by supplied vid for event handlers
	 wm.windows[vid] = wnd

	 table.insert(wndlist, wnd)
	 return wnd
end


return window
