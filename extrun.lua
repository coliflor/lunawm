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
	 target_displayhint(vid, opts.w, opts.h, TD_HINT_IGNORE, {ppcm = VPPCM, anchor = wnd.anchor}); -- Pass the anchor
	 return wnd
end

function prio_target_window(tgt, cfg, x, y, w, h, force, shader)
	 launch_target(tgt, cfg, LAUNCH_INTERNAL,
								 function(source, status)
										if (status.kind == "preroll") then
											 local wnd = setup_wnd(source, status.source_audio,
																						 {x = x, y = y, w = w, h = h,
																							force_size = force});
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

local whitelist = {
	 "lightweight arcan", "multimedia",
	 "terminal", "tui", "remoting", "game", "vm", "application",
	 "browser", "bridge-x11", "bridge-wayland",
};

function dump(o)
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

function client_event_handler(source, status)

	 print("client_event_handler called:")
	 print(dump(status))
	 print(dump(source))

	 if status.kind == "terminated" then
			delete_image(source)
	 elseif status.kind == "resized" then
			--resize_image(source, status.width, status.height)
	 elseif status.kind == "connected" then
			target_alloc(connection_point, client_event_handler)
	 elseif status.kind == "registered" then
	 elseif status.kind == "preroll" then
			local proptbl = {
				 x = 0,
				 y = 0,
				 w = 32,
				 h = 32,
				 force_size = priocfg.force_size,
				 autocrop = true,
			};

			local wnd = setup_wnd(source, status.source_audio, proptbl);

			table.insert(tags[current_tag], wnd); -- Add window directly to tags

			arrange(tags, current_tag); -- Call arrange after adding the window

			target_updatehandler(source, prio_group_handler);
			send_type_data(source, "terminal");

			wnd:select();
			wnd.listen_key = key;
	 elseif status.kind == "segment_request" and status.segkind == "clipboard" then
	 end
end

function prio_terminal(x, y, w, h, passed_arrange)
	 local arrange = passed_arrange;
	 local arg = priocfg.terminal_cfg .. "env=ARCAN_CONNPATH=" .. connection_point;

	 launch_avfeed(arg, "terminal", function(source, status)
										if (status.kind == "preroll") then
											 client_event_handler(source, status);
										end
	 end);
end
