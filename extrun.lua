local defevhs = {};

local function cursor_handler(wnd, source, status)
    if (status.kind == "terminated") then
        delete_image(source);
        wnd.mouse_cursor = nil;
        local mx, my = mouse_xy();
        if (image_hit(wnd.canvas, mx, my)) then
            wnd:over();
        end
    end
end

local function clipboard_handler(wnd, source, status)
	 if (status.kind == "message") then
			if (not wnd.multipart) then
				 wnd.multipart = {};
			end
			table.insert(wnd.multipart, status.message);
			if (not status.multipart) then
				 wnd.clipboard_message = table.concat(wnd.multipart, "");
				 CLIPBOARD_MESSAGE = wnd.clipboard_message;
				 wnd.multipart = {};
			end
	 elseif (status.kind == "terminated") then
			delete_image(source);
	 end
end

defevhs["resized"] =
	 function(wnd, source, status)
			wnd.flip_y = status.origo_ll;

			if (wnd.target == source) then
				 wnd.aid = source_audio;
				 if (wnd.force_size) then
						wnd:resize(wnd.width, wnd.height);
				 else
						wnd:resize(status.width, status.height, true);
				 end
				 wnd:update_tprops();
			end
	 end

defevhs["terminated"] =
	 function(wnd, source, status)
			wnd:lost(source);
	 end

defevhs["segment_request"] =
	 function(wnd, source, stat)
			if (stat.segkind == "clipboard" and tab) then
				 if (valid_vid(tab.clipboard_in)) then
						delete_image(tab.clipboard_in);
				 end
				 tab.clipboard_in = accept_target(
						function(src, stat)
							 clipboard_handler(wnd, src, stat);
				 end);
				 link_image(tab.clipboard_in, wnd.anchor);

				 -- a little complicated, some clients (like games) start with
				 -- no cursor and might enable one as a custom subsegment
			elseif (stat.segkind == "cursor") then
				 local new = accept_target(
						function(src, stat)
							 cursor_handler(wnd, src, stat);
						end
				 );
				 if (valid_vid(new)) then
						link_image(new, wnd.anchor);
						if (wnd.active_tab == tab) then
							 wnd.mouse_cursor = new;
							 local mx,my = mouse_xy();
							 if (image_hit(wnd.canvas, mx, my)) then
									wnd:over();
							 end
						end
						tab.mouse_cursor = new;
				 end
			else
				 -- just reject
			end
	 end

function prio_group_handler(source, status)
	 local wnd = priowindows[source];
	 if (wnd and defevhs[status.kind]) then
			defevhs[status.kind](wnd, source, status);
	 end
end

-- allow static images at specific positions
function prio_static_image(resource, x, y, w, h, opts)
	 opts = opts and opts or {};

	 load_image_asynch(resource, function(hnd, status)
												if (status.kind == "loaded") then
													 force_image_blend(hnd, BLEND_FORCE);
													 order_image(hnd, opts.order and opts.order or 2);
													 blend_image(hnd, 1.0, priocfg.animation_speed);
													 if (w and h and w > 0 and h > 0) then
															resize_image(hnd, w, h);
													 else
															resize_image(hnd, status.width, status.height);
													 end
													 move_image(hnd, x, y);

												else
													 delete_image(hnd);
													 warning("could not load " .. tostring(resource and resource or ""));
												end
	 end);
end

local function send_type_data(source, segkind)
	 local dstfont_sz = priocfg.default_font_sz;
	 local dstfont = priocfg.default_font;

	 if (segkind == "terminal" or segkind == "tui") then
			dstfont = priocfg.terminal_font;
			dstfont_sz = priocfg.terminal_font_sz;
	 end

	 for i,v in ipairs(dstfont) do
			target_fonthint(source, v, dstfont_sz, priocfg.terminal_hint, i > 1);
	 end
end

local function setup_wnd(vid, aid, opts)
	 if (not valid_vid(vid, TYPE_FRAMESERVER)) then
			return;
	 end

	 local wnd = prio_new_window(vid, aid, opts) -- Get the window object returned by prio_new_window
	 target_displayhint(vid, opts.w, opts.h, 0, {ppcm = VPPCM, anchor = wnd.anchor}); -- Pass the anchor
	 return wnd
end

function prio_target_window(tgt, cfg, x, y, w, h, force, shader)
	 launch_target(tgt, cfg, LAUNCH_INTERNAL,
								 function(source, status)
										if (status.kind == "preroll") then
											 local wnd = setup_wnd(source, status.source_audio,
																						 {x = x, y = y, w = w, h = h,
																							force_size = force}, shader);
											 target_updatehandler(source, prio_group_handler);
											 if (wnd) then
													wnd:select();
											 end
										end
								 end
	 );
end

-- append / add type- specific options to the window configuration
local function wnd_type_options(segkind, orig_opts)
	 local set_if = function(tbl, k, v)
			if (not tbl[k]) then
				 tbl[k] = v;
			end
	 end

	 if (not orig_opts) then
			orig_opts = {};
	 end

	 if (segkind == "terminal" or segkind == "tui") then
			set_if(orig_opts, "autocrop", true);
	 end

	 if (segkind == "game" or segkind == "lightweight arcan" or
			 segkind == "multimedia" or segkind == "bridge-x11") then
			set_if(orig_opts, "mouse_hidden", true);
	 end

	 local cl = priocfg.tab_colors[segkind];
	 if (cl and (#cl == 6 or #cl == 3)) then
			if (#cl == 3) then
				 cl[4] = cl[1] * 0.5;
				 cl[5] = cl[2] * 0.5;
				 cl[6] = cl[3] * 0.5;
			end
			set_if(orig_opts, "active_color", {cl[1], cl[2], cl[3]});
			set_if(orig_opts, "inactive_color", {cl[4], cl[5], cl[6]});
	 end

	 return orig_opts;
end

local pending = {};
local whitelist = {
	 "lightweight arcan", "multimedia",
	 "terminal", "tui", "remoting", "game", "vm", "application",
	 "browser", "bridge-x11", "bridge-wayland"
};

local function limbo_handler(source, status)
	 if (status.kind == "resized") then
			local wnd = pending[source][1];
			local seg = pending[source][2];
			target_updatehandler(source, prio_group_handler);
			priowindows[source] = wnd;
			local tab = wnd:add_tab(source, nil,
															wnd_type_options(seg, {force_size = wnd.force_size}));
			pending[source] = nil;
			if (not tab) then
				 delete_image(source);
				 return;
			end
			prio_group_handler(source, status);
	 elseif (status.kind == "terminated") then
			delete_image(source);
			pending[source] = nil;
	 end
end

local function terminal_listen(wnd)
	 if (wnd.listen_key == nil) then
			--		print("DEBUG STATE, track:", debug.traceback());
			return;
	 end

	 target_alloc(wnd.listen_key, function(source, status)
									 if (status.kind == "preroll") then
											local found = false;
											for i,v in ipairs(whitelist) do
												 if (status.segkind == v) then
														found = true;
														break;
												 end
											end

											if (not found) then
												 delete_image(source);
												 return;
											end

											send_type_data(source, status.segkind);
											target_displayhint(source, wnd.width, wnd.height, 0, {ppcm = VPPCM});
											pending[source] = {wnd, status.segkind};
											target_updatehandler(source, limbo_handler);

									 elseif (status.kind == "terminated") then
											delete_image(source);
											pending[source] = nil;
									 end
									 terminal_listen(wnd);
	 end);
end

function prio_listen(key, keep_offline, x, y, w, h, opts)
	 local alloc;
	 local last_source;

	 alloc = function()
			target_alloc(key, function(source, status)
											if (status.kind == "terminated") then
												 if (keep_offline) then
														if (valid_vid(last_source)) then
															 delete_image(last_source);
														end
														last_source = source;
												 else
														delete_image(source);
												 end
												 alloc();
											elseif (status.kind == "resized") then
												 if (valid_vid(last_source)) then
														delete_image(last_source);
														last_source = source;
												 end
												 show_image(source);
												 move_image(source, x, y);
												 resize_image(source, w, h);
											elseif (status.kind == "preroll") then
												 target_displayhint(source, w, h);
											end
			end);
	 end

	 alloc();
end

local charset = "abcdefhigjklmnopqrstuvwxyz1234567890";
local csetlen = string.len(charset);
function prio_terminal(x, y, w, h, clients, passed_arrange)
    local arrange = passed_arrange;

    local key = "prio_term_";
    for i = 1, 10 do
        local ind = math.random(1, csetlen);
        key = key .. string.sub(charset, ind, ind);
    end

    local arg = priocfg.terminal_cfg .. "env=ARCAN_CONNPATH=" .. key;
    opts = wnd_type_options("terminal", opts);

    launch_avfeed(arg, "terminal", function(source, status)
        if (status.kind == "preroll") then
            local proptbl = {
                x = x,
                y = y,
                w = w,
                h = h,
                force_size = priocfg.force_size,
                autocrop = true,
            };
            for k, v in pairs(opts) do
                proptbl[k] = v;
            end
            local wnd, tab = setup_wnd(source, status.source_audio, proptbl, proptbl.shader);

            if (not wnd) then
                delete_image(source);
                return;
            end

            table.insert(clients, wnd); -- Add window directly to clients
            table.insert(tags[current_tag], wnd); -- Add window directly to tags

            arrange(tags, current_tag); -- Call arrange after adding the window

            target_updatehandler(source, prio_group_handler);
            send_type_data(source, "terminal");

            wnd:select();
            wnd.listen_key = key;
            terminal_listen(wnd);
        end
    end);
end
