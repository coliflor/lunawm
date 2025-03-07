local dirtbl = {"l", "r", "t", "b"}
local window_id_counter = 0 -- Initialize a counter for window IDs
local wndlist = {}
local hidden = {}

-- ----------------------------------------------------
--  helper functions for window spawn
-- ----------------------------------------------------
local defevhs = {}

local function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function cursor_handler(wnd, source, status)
	 print("cursor: " .. status.kind)
	 if (status.kind == "terminated") then
			delete_image(source)
			wnd.mouse_cursor = nil
			local mx, my = mouse_xy()
			if (image_hit(wnd.canvas, mx, my)) then
				 wnd:over()
			end
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
				 CLIPBOARD_MESSAGE = wnd.clipboard_message
				 wnd.multipart = {}
			end
	 elseif (status.kind == "terminated") then
			delete_image(source)
	 end
end

defevhs["resized"] = function(wnd, source, status)
	 wnd.flip_y = status.origo_ll

	 if (wnd.target == source) then
			wnd.aid = source_audio
			if (wnd.force_size) then
				 -- Use tag-specific dimensions if available, otherwise use global wnd.width and wnd.height
				 local current_tag = wm.current_tag
				 if wnd.tags[current_tag] then
						wnd:resize(wnd.tags[current_tag].width, wnd.tags[current_tag].height)
				 end
			else
				 wnd:resize(status.width, status.height, true)
			end
			wnd:update_tprops()
	 end
end

defevhs["terminated"] =
	 function(wnd, source, status)
			wnd:lost(source)
	 end

defevhs["ident"] =
	 function(wnd, source, status)
			wnd.ident = status.message
	 end

defevhs["segment_request"] =
	 function(wnd, source, stat)
			print("segment_request " .. stat.segkind)
			if (stat.segkind == "cursor") then
				 local new = accept_target(function(src, stat)
							 cursor_handler(wnd, src, stat)
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

function prio_group_handler(source, status)
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

	 local wnd = prio_new_window(vid, aid, opts) -- Get the window object returned by prio_new_window
	 target_displayhint(vid, opts.w, opts.h, TD_HINT_IGNORE, {ppcm = VPPCM, anchor = wnd.anchor}) -- Pass the anchor
	 return wnd
end

function prio_target_window(tgt, cfg, x, y, w, h, force)
	 launch_target(tgt, cfg, LAUNCH_INTERNAL,
								 function(source, status)
										if (status.kind == "preroll") then
											 local wnd = setup_wnd(source, status.source_audio,
																						 {x = x, y = y, w = w, h = h,
																							force_size = force})
											 target_updatehandler(source, prio_group_handler)
											 if (wnd) then
													wnd:select()
											 end
										end
								 end
	 )
end

function client_event_handler(source, status)

	 print("client_event_handler called:")
	 print(dump(status))
	 print(dump(source))

	 if status.kind == "terminated" then
			delete_image(source)
	 elseif status.kind == "resized" then
			--resize_image(source, status.width, status.height)
	 elseif status.kind == "connected" then
			target_alloc(wm.cfg.conn_point, client_event_handler)
	 elseif status.kind == "registered" then
	 elseif status.kind == "preroll" then
			local proptbl = {
				 x = 0,
				 y = 0,
				 w = 32,
				 h = 32,
				 force_size = wm.cfg.force_size,
				 autocrop = true,
			}

			local wnd = setup_wnd(source, status.source_audio, proptbl)

			table.insert(wm.tags[wm.current_tag], wnd) -- Add window directly to tags

			arrange() -- Call arrange after adding the window

			target_updatehandler(source, prio_group_handler)
			send_type_data(source, "terminal")

			wnd:select()
	 elseif status.kind == "segment_request" and status.segkind == "clipboard" then
	 end
end

function terminal()
	 local arg = wm.cfg.terminal_cfg .. "env=ARCAN_CONNPATH=" .. wm.cfg.conn_point

	 launch_avfeed(arg, "terminal", function(source, status)
										if (status.kind == "preroll") then
											 client_event_handler(source, status)
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

function prio_windows_linear(hide_hidden)
	 local res = {}
	 for _,v in ipairs(wndlist) do
			if (not hide_hidden or not hidden[v]) then
				 table.insert(res, v)
			end
	 end

	 return res
end

function reorder_windows()
	 for i,v in ipairs(wndlist) do
			order_image(v.anchor, (i+1) * 10)
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
	 for i,v in ipairs(dirtbl) do
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
	 if (wnd.autocrop or wnd.force_size or not
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
function set_trigger_point(ctx, vid)
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

function decor_v_drag(ctx, vid, dx, dy)
	 if (ctx.wnd ~= priowin) then
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
	 else
			-- means the _over event didn't fire before drag, shouldn't happen
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

function decor_h_drag(ctx, vid, dx, dy)
	 if (ctx.wnd ~= priowin) then
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
end

local function decor_v_over(ctx, vid, x, y)
	 if (ctx.wnd ~= priowin) then
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

local function decor_h_over(ctx, vid, x, y)
	 if (ctx.wnd ~= priowin) then
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

local function get_maximize_dir()
	 local x, y = mouse_xy()
	 if (x <= 5) then
			return "l"
	 end
	 if (x >= VRESW-5) then
			return "r"
	 end
	 if (y <= 5) then
			return "t"
	 end
	 if (y >= VRESH-5) then
			return "b"
	 end
end

local function decor_sel(ctx)
	 ctx.wnd:select()
end

local function decor_reset()
	 mouse_switch_cursor()
end

-- build the decorations: tttt
--                        l  r
--                        bbbb and anchor for easier resize
local function build_decorations(wnd, opts)
	 local bw = wm.cfg.border_width

	 if bw == 0 then
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

	 for k, v in ipairs(dirtbl) do
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
				 drag = decor_v_drag,
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
				 drag = decor_h_drag,
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
				 drag = decor_v_drag,
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

function rebuild_all_decorations()
	 for _, wnd in ipairs(wndlist) do
			-- Assuming 'opts' is available or can be reconstructed
			build_decorations(wnd, { no_decor = true })
	 end
end

local function window_resize(wnd, neww, newh, nofwd)
	 local pad_v = wnd.margin.t - wnd.margin.b
	 local pad_h = wnd.margin.l - wnd.margin.r
	 neww = (neww > VRESW - pad_h) and (VRESW - pad_h) or neww
	 newh = (newh > VRESH - pad_v) and (VRESH - pad_v) or newh

	 resize_image(wnd.canvas, neww, newh)
	 resize_image(wnd.anchor, neww, newh)
	 window_decor_resize(wnd, neww, newh)

	 local current_tag = wm.current_tag
	 local tag_data = wnd.tags[current_tag]

	 if (not tag_data) then
			tag_data = wnd.tags[get_first_tag_with_data(wnd)]
	 end

	 if ((neww ~= tag_data.width or newh ~= tag_data.height)
			and not nofwd and valid_vid(wnd.target, TYPE_FRAMESERVER)) then
			target_displayhint(wnd.target, neww, newh)
	 end

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

	 for k,v in ipairs(wnd.event_hooks) do
			v(wnd, "resize")
	 end
end

local function find_nearest(bp_x, bp_y, dir)
	 local lst = {}
	 for k,v in pairs(wm.windows) do
			local props = image_surface_resolve_properties(v.canvas)
			local cx = bp_x - (props.x + 0.5 * props.width)
			local cy = bp_y - (props.y + 0.5 * props.height)
			local dist
			if (dir) then
				 if (dir == "t" and cy > 0) then
						table.insert(lst, {wnd = v, dist = cy})
				 elseif (dir == "l" and cx > 0) then
						table.insert(lst, {wnd = v, dist = cx})
				 elseif (dir == "r" and cx < 0) then
						table.insert(lst, {wnd = v, dist = -cx})
				 elseif (dir == "b" and cy < 0) then
						table.insert(lst, {wnd = v, dist = -cy})
				 end
			else
				 local dist = math.sqrt(cx * cx + cy * cy)
				 table.insert(lst, {wnd = v, dist = dist})
			end
	 end

	 for i=#lst,1,-1 do
			if (lst[i].wnd.select_block) then
				 table.remove(lst, i)
			end
	 end

	 table.sort(lst, function(a, b) return a.dist < b.dist end)
	 return lst
end

function prio_sel_nearest(wnd, dir)
	 local props = image_surface_resolve_properties(wnd.canvas)
	 local lst = find_nearest(props.x + props.width * 0.5,
														props.y + props.height * 0.5, dir)
	 if (lst[1]) then
			lst[1].wnd:select()
	 end
end

function window_select(wnd)
	 if (priostate and priostate(wnd)) then
			return
	 end

	 if (priowin) then
			if (priowin ~= wnd) then
				 priowin:deselect()
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

	 priowin = wnd
	 if (valid_vid(wnd.target)) then
			wnd.dispmask = (bit.band(wnd.dispmask, bit.bnot(TD_HINT_UNFOCUSED)))
			target_displayhint(wnd.target, 0, 0, wnd.dispmask)
	 end
	 wnd:border_color(unpack(wm.cfg.active_color))
	 reorder_windows()

	 for k,v in ipairs(wnd.event_hooks) do
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
	 if (priowin == wnd) then
			priowin = nil
	 end

	 for k,v in ipairs(wnd.event_hooks) do
			v(wnd, "deselect")
	 end
end

local function window_lost(wnd, source)
	 wnd:destroy()
end

local function window_hide(wnd)
	 if (wnd.delete_protect) then
			return
	 end

	 wnd:deselect()
	 hide_image(wnd.anchor)
	 for k,v in ipairs(wnd.event_hooks) do
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

				 for k, v in ipairs(wnd.event_hooks) do
						v(wnd, "show")
				 end
				 return
			end
	 end
end

local function window_destroy(wnd)
	 local cp = image_surface_resolve_properties(wnd.canvas)
	 if (priowin == wnd) then
			priowin = nil
	 end

	 local mx, my = mouse_xy()
	 if (image_hit(wnd.canvas, mx, my)) then
			mouse_switch_cursor()
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
	 for k, v in pairs(wnd.decor_mh) do
			mouse_droplistener(v)
	 end
	 mouse_droplistener(wnd)

	 for k, v in ipairs(wnd.event_hooks) do
			v(wnd, "destroy")
	 end

	 -- anchor will just cascade delete everything.
	 print("Deleting window anchor:", wnd.anchor) -- Debug
	 delete_image(wnd.anchor)

	 -- but reset the table to identify any dangling refs.
	 for k, v in pairs(wnd) do
			wnd[k] = nil
	 end
	 wnd.dead = true

	 -- find something else to select
	 if (not priowin) then
			-- Select the next window in line
			if #wndlist > 0 then
				 wndlist[#wndlist]:select()
			else
				 find_nearest(cp.x + 0.5 * cp.width, cp.y + 0.5 * cp.y, 1, 1)
			end
	 end

	 -- Remove from tags list
	 local window_id = wnd.id -- Get the window ID

	 for t, tag in pairs(wm.tags) do
			for j, c in ipairs(tag) do
				 if c == wnd then
						print("Removed window from tag:", t) -- Debug
						table.remove(tag, j)
						break
				 end
			end
	 end

	 -- Call arrange AFTER removing the wnd
	 arrange()
end

local function window_move(wnd, x, y)
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

local function step_sz(wnd)
	 local ssx = wnd.inertia and wnd.inertia[1] or wm.cfg.drag_resize_inertia
	 local ssy = wnd.inertia and wnd.inertia[2] or wm.cfg.drag_resize_inertia
	 return ssx, ssy
end

local function window_step_move(wnd, steps, xd, yd)
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

local function window_mousemotion(ctx, vid, x, y)

   if (ctx.drag_data) then
			window_drag_move(ctx, x, y)
			return -- Prevent further processing
	 end

	 local outm = {
			kind = "analog",
			mouse = true,
			relative = false,
			devid = 0,
			subid = 0,
			samples = {0}
	 }
	 if (not valid_vid(ctx.target, TYPE_FRAMESERVER)) then
			return
	 end

	 local props = image_surface_resolve_properties(ctx.anchor)
	 outm.samples[1] = x - props.x

	 -- relative or absolute? for absolute, we need to scale
	 target_input(ctx.target, outm)
	 outm.samples[1] = y - props.y
	 outm.subid = 1
	 target_input(ctx.target, outm)
end

local function window_drag_start(wnd, x, y)
	 if (not wnd.drag_data) then
			wnd.drag_data = {
				 start_x = x,
				 start_y = y,
				 wnd_x = image_surface_resolve_properties(wnd.anchor).x,
				 wnd_y = image_surface_resolve_properties(wnd.anchor).y
			}
	 end
end

function window_drag_move(wnd, x, y)
	 if (wnd.drag_data) then
			local dx = x - wnd.drag_data.start_x
			local dy = y - wnd.drag_data.start_y
			wnd:move(wnd.drag_data.wnd_x + dx, wnd.drag_data.wnd_y + dy)
	 end
end

local function window_drag_end(wnd)
	 wnd.drag_data = nil
end

local function window_mousebutton(ctx, devid, ind, act)
	 -- trick to avoid spurious "release" events being forwarded
	 if (ctx == priowin) then
			if (priowin.tab_cooldown) then
				 priowin.tab_cooldown = nil
				 return
			end
	 else
			if (act) then
				 ctx:select()
			end
			return
	 end

	 if (priostate and priostate(ctx)) then
			return
	 end

	 if (act and ind == 1 and wm.mod_key_pressed) then -- Left click pressed and mod key pressed
			window_drag_start(ctx, mouse_xy())
			return -- Prevent further processing
	 end

	 if (not act and ind == 1 and ctx.drag_data) then
			window_drag_end(ctx)
			return -- Prevent further processing
	 end

	 if (ctx.mouse_btns and ctx.mouse_btns[ind] ~= act) then
			ctx.mouse_btns[ind] = act
			if (valid_vid(ctx.target, TYPE_FRAMESERVER)) then
				 target_input(ctx.target, {digital = true, mouse = true,
																	 devid = 0, subid = ind, active = act})
			end
	 end
end

local function window_mouseover(ctx)
	 if (ctx.wnd and ctx.wnd ~= priowin) then -- Check if window exists and is not already focused
			ctx.wnd:select() -- Select the window on mouseover
	 end

	 if (ctx.mouse_cursor) then
			mouse_custom_cursor(ctx.mouse_cursor)
	 elseif (ctx.mouse_hidden) then
			mouse_hide()
	 else
			mouse_switch_cursor()
	 end
end

local function window_mouseout(ctx)
	 mouse_show()
	 mouse_switch_cursor()

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

-- Return an iterator for iterating windows, windows-with-external
-- connection
function prio_iter_windows(external)
	 local ctx = {}

	 for k,v in pairs(wm.windows) do
			if (not external or valid_vid(v.target, TYPE_FRAMESERVER)) then
				 table.insert(ctx, k, v)
			end
	 end

	 local i = 0
	 local c = #ctx
	 return function()
			i = i + 1
			return ctx[i]
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
			if (wnd.active_tab) then
				 wnd.active_tab.clipboard_out = tgt_clip
				 link_image(tgt_clip, wnd.active_tab.vid)
			else
				 link_image(wnd.clipboard_out, wnd.anchor)
			end
	 end

	 -- slightly incorrect as target_input can come up short, the
	 -- real option is to have a background timer and continously flush
	 if (msg and string.len(msg) > 0) then
			target_input(wnd.clipboard_out, msg)
	 end
end

-- ----------------------------------------------------
-- window arrange functions
-- ----------------------------------------------------

function arrange()
	 local tag = wm.tags and wm.tags[wm.current_tag] or {}
	 local n = #tag

	 if n == 0 then return end

	 if wm.cfg.layout_mode == "monocle" then
			arrange_monocle(tag)
	 elseif wm.cfg.layout_mode == "middle_stack" then
			arrange_master_middle_stack(tag)
	 elseif wm.cfg.layout_mode == "grid" then
			arrange_grid(tag)
	 else -- Default to the existing master/stack layout
			arrange_master_stack(tag)
	 end
end

function arrange_monocle(tag)
	 local gap = wm.cfg.window_gap or 5
	 local n = #tag
	 local statusbar_height = wm.cfg.statusbar_height or 20
	 local statusbar_position = wm.cfg.statusbar_position or "bottom"

	 for i = 1, n do
			local wnd = tag[i]
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

function arrange_grid(tag)
	 local n = #tag
	 local gap = wm.cfg.window_gap or 5
	 local statusbar_height = wm.cfg.statusbar_height or 20
	 local statusbar_position = wm.cfg.statusbar_position or "bottom"

	 local cols = math.ceil(math.sqrt(n))
	 local rows = math.ceil(n / cols)

	 local tile_width = VRESW / cols
	 local tile_height = (VRESH - statusbar_height) / rows

	 local index = 1
	 for row = 1, rows do
			for col = 1, cols do
				 if index <= n then
						local wnd = tag[index]
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

function arrange_master_middle_stack(tag)
	 local n = #tag
	 local statusbar_height = wm.cfg.statusbar_height or 20
	 local statusbar_position = wm.cfg.statusbar_position or "bottom"

	 if n == 1 then
			arrange_monocle(tag)
			return
	 end

	 local master_area_w = VRESW * wm.cfg.master_ratio
	 local master_area_h = VRESH - statusbar_height
	 local stack_area_w = (VRESW - master_area_w) / 2
	 local stack_area_h = VRESH - statusbar_height

	 local gap = wm.cfg.window_gap or 5

	 -- Master window (n > 1)
	 local master = tag[1]
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
				 table.insert(left_stack, tag[i])
			else
				 table.insert(right_stack, tag[i])
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

function arrange_master_stack(tag)
	 local n = #tag
	 local statusbar_height = wm.cfg.statusbar_height or 20
	 local statusbar_position = wm.cfg.statusbar_position or "bottom"

	 if n == 1 then
			arrange_monocle(tag)
			return
	 end

	 local master_area_w = VRESW * wm.cfg.master_ratio
	 local master_area_h = VRESH - statusbar_height
	 local stack_area_x = master_area_w
	 local stack_area_w = VRESW - master_area_w
	 local stack_area_h = VRESH - statusbar_height

	 local gap = wm.cfg.window_gap or 5

	 -- Master window (n > 1)
	 local master = tag[1]
	 local pad_w = master.margin.l + master.margin.r
	 local pad_h = master.margin.t + master.margin.b

	 local master_y = master.margin.t + gap / 2
	 if statusbar_position == "top" then
			master_y = master_y + statusbar_height
	 end

	 master:move(master.margin.l + gap / 2, master_y)
	 master:resize(master_area_w - pad_w - gap, master_area_h - pad_h - gap)

	 -- Stack windows (n > 1)
	 local stack_h = (stack_area_h - (n - 2) * gap) / (n - 1)
	 for i = 2, n do
			local wnd = tag[i]
			local pad_w = wnd.margin.l + wnd.margin.r
			local pad_h = wnd.margin.t + wnd.margin.b

			local wnd_y = (i - 2) * stack_h + wnd.margin.t + gap / 2 + (i - 2) * gap
			if statusbar_position == "top" then
				 wnd_y = wnd_y + statusbar_height
			end

			wnd:move(stack_area_x + wnd.margin.l + gap / 2, wnd_y)
			wnd:resize(stack_area_w - pad_w - gap, stack_h - pad_h - gap)
	 end
end

function set_layout_mode(mode)
	 wm.cfg.layout_mode = mode
	 arrange() -- Re-arrange windows after changing layout
end

function prio_new_window(vid, aid, opts)
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

	 window_id_counter = window_id_counter + 1 -- Increment the counter
	 local wnd = {
			id = window_id_counter, -- Assign the current counter value as the ID
			name = "prio_window",
			anchor = anchor,
			canvas = vid,
			aid = aid,
			min_w = 32,
			min_h = 32,
			width = opts.w,
			height = opts.h,
			created = CLOCK,
			dispmask = 0, -- tracking display state
			event_hooks = {},
			title = "",
			ident = "",

			-- decorations
			decor = {},
			decor_mh = {},
			margin = {t = 0, l = 0, r = 0, b = 0},

			-- input controls
			mscale = {},
			own = vid,
			mouse_btns = {},

			-- window maipulation
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
			update_tprops = window_update_tprops,
			paste = window_paste,

			-- projectable toggles
			delete_protect = opts.delete_protect,
			tab_block = opts.tab_block,
			select_block = opts.select_block,

			-- per tab toggles
			force_size = opts.force_size,
			autocrop = opts.autocrop,
			flip_y = opts.flip_y,

			tags = {},
	 }

	 wnd.tags[wm.current_tag] = {
			width = opts.w,
			height = opts.h,
			x = opts.x,
			y = opts.y,
	 }

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

	 table.insert(wndlist, wnd)

	 -- index by supplied vid for event handlers
	 wm.windows[vid] = wnd
	 return wnd
end
