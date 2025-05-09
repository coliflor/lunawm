wm = {
	 sym = {},
	 cfg = {},
	 actions = {},
	 bindings = {}, -- keybindings
	 var = {}, -- variables
	 win = {}, -- window manager

	 arrangers = {},
	 layout_modes = {},

	 windows = {},
	 window = {},

	 bg = nil, -- background

	 -- Tiling-specific data
	 tags = {},  -- (workspaces)
	 current_tag = 1, -- Currently active tag
	 last_tag = 1,

	 -- Global variable to track mod key state
	 mod_key_pressed = false,

	 clip = {},
	 CLIPBOARD_MESSAGE = "",

	 -- functions
	 arrange = {},
	 toboolean = {},
	 fuse_tags = {},
	 view_tag = {},
	 terminal = {},
	 set_layout_mode = {},
	 rebuild_all_decorations = {},
	 client_event_handler = {},

	 debug_message = "",
}

local last_msg
local function system_message(str)
	 local msg, _, _, h = render_text({[[\#000000]] .. str})
	 if (valid_vid(last_msg)) then
			delete_image(last_msg)
	 end
	 last_msg = msg

	 if (valid_vid(msg)) then
			expire_image(msg, 50)
			move_image(msg, 0, VRESH - h)
			show_image(msg)
			order_image(msg, 65535)
	 end
end

function lunawm()

	 wm.sym = system_load("builtin/keyboard.lua")() -- keyboard translation
	 wm.cfg = system_load("config.lua")()
	 system_load("builtin/mouse.lua")() -- mouse gesture abstraction etc.
	 system_load("timer.lua")()
	 wm.win = system_load("window.lua")() -- window creation
	 wm.var = system_load("variables.lua")()
	 wm.actions = system_load("actions.lua")() -- bindable actions
	 system_load("ipc.lua")()
	 wm.bindings = system_load("keybindings.lua")() -- keysym+mods -> actions

	 wm.arrangers = {
			floating = system_load("arrange/floating.lua")(),
			monocle = system_load("arrange/monocle.lua")(),
			grid = system_load("arrange/grid.lua")(),
			middle_stack = system_load("arrange/master_midle_stack.lua")(),
			master_stack = system_load("arrange/master_stack.lua")(),
	 }

	 for mode, _ in pairs(wm.arrangers) do
			table.insert(wm.layout_modes, mode)
	 end

	 wm.arrange = wm.win.arrange
	 wm.fuse_tags = wm.actions.fuse_tags
	 wm.view_tag = wm.actions.view_tag
	 wm.terminal = wm.win.terminal
	 wm.set_layout_mode = wm.win.set_layout_mode
	 wm.rebuild_all_decorations = wm.win.rebuild_all_decorations
	 wm.client_event_handler = wm.win.client_event_handler

	 -- Initialize tags:
	 for i = 1, wm.cfg.num_tags do
			wm.tags[i] = {}
	 end

	 -- mipmap is build-time default off, vfilter is bilinear
	 switch_default_texfilter(FILTER_NONE)

	 -- default gain value for all new sources
	 audio_gain(0, wm.cfg.global_gain)

	 -- some platforms/devices don't support this and we should provide
	 -- a fallback, but that's missing now
	 kbd_repeat(wm.cfg.repeat_period, wm.cfg.repeat_delay)

	 -- we'll always "overdraw" when updating due to the background image
	 rendertarget_noclear(WORLDID, true)
	 wm.bg = fill_surface(VRESW, VRESH, 64, 64, 64)
	 show_image(wm.bg)

	 -- asynch- load background and overwrite existing if found
	 if (wm.cfg.background and resource(wm.cfg.background)) then
			load_image_asynch(wm.cfg.background,
												function(source, status)
													 if (status.kind == "loaded") then
															image_sharestorage(source, wm.bg)
													 end
													 delete_image(source)
			end)
	 end

	 local add_cursor = function(name, hx, hy)
			mouse_add_cursor(name, load_image("cursor/" ..name ..".png"), hx, hy, {})
	 end

	 add_cursor("def", 0, 0)
	 add_cursor("rz_diag_l", 0, 0)
	 add_cursor("rz_diag_r", 0, 0)
	 add_cursor("rz_down", 0, 0)
	 add_cursor("rz_left", 0, 0)
	 add_cursor("rz_right", 0, 0)
	 add_cursor("rz_up", 0, 0)
	 add_cursor("hide", 0, 0)
	 add_cursor("grabhint", 0, 0)
	 add_cursor("drag", 0, 0)
	 add_cursor("destroy", 6, 7)
	 add_cursor("new", 8, 6)

	 wm.sym:load_keymap(wm.cfg.keymap)

	 -- try mouse- grab (if wanted)
	 mouse_setup(BADID, {
									order = 65535,
									pickdepth = 1
	 })

	 mouse_cursor_sf(wm.cfg.mouse_cursor_scale, wm.cfg.mouse_cursor_scale)
	 mouse_switch_cursor("def", true)

	 -- rebuild config now that we have access to everything
	 lunawm_update_density(VPPCM)

	 target_alloc(wm.cfg.conn_point, wm.client_event_handler)

	 if wm.cfg.debug_mode == true then
			wm.debug_message = system_message
	 else
			wm.debug_message = function() end
	 end

end

-- Function to set the mod key state
local function set_mod_key_state(active)
	 wm.mod_key_pressed = active
end

-- two modes, one with normal forwarding etc. one with a region-select
function lunawm_normal_input(iotbl)
	 if (iotbl.mouse) then
			mouse_iotbl_input(iotbl)
			return

			-- on keyboard input, apply translation and run any defined keybinding
			-- for synthetic keyrepeat, the patch result would need to be cached and
			-- propagated in the _clock_pulse.
	 elseif (iotbl.translated) then
			local _, b = wm.sym:patch(iotbl, true)

			-- falling edge (release) gets its own suffix to allow binding something on
			-- rising edge and something else on falling edge
			if (not iotbl.active) then
				 b = b .. "_f"
			end

			-- Check if it's a mod key and update the global state
			if (wm.sym:is_modifier(iotbl)) then
				 set_mod_key_state(iotbl.active) -- Update global mod key state
			end

			-- slightly more difficult for dealing with C-X, C-W style choords where
			-- C-* is bound to a translation prefix and the next non-modifier press
			-- consumes it
			if (iotbl.active and wm.sym.prefix and
					not wm.sym:is_modifier(iotbl)) then
				 b = wm.sym.prefix .. b
				 wm.sym.prefix = nil
			end

			wm.debug_message(string.format(
											 "resolved symbol: %s, binding? %s, action? %s", b,
											 wm.bindings[b] and wm.bindings[b] or "[missing]",
											 (wm.bindings[b] and wm.actions[wm.bindings[b]]) and "yes" or "no"))

			if (wm.bindings[b] and wm.actions[wm.bindings[b]]) then
				 wm.actions[wm.bindings[b]]()
				 return
			end
	 end

	 -- we have a keyboard key without a binding OR a game/other device,
	 -- forward normally if the window is connected to an external process
	 if (wm.window and valid_vid(wm.window.target, TYPE_FRAMESERVER)) then
			target_input(wm.window.target, iotbl)
	 end
end

-- Return an iterator for iterating windows, windows-with-external connection
local function iter_windows(external)
	 local ctx = {}

	 for k,v in pairs(wm.windows) do
			if (not external or valid_vid(v.target, TYPE_FRAMESERVER)) then
				 table.insert(ctx, k, v)
			end
	 end

	 local i = 0
	 return function()
			i = i + 1
			return ctx[i]
	 end
end

function lunawm_update_density(vppcm)
	 VPPCM = vppcm
	 wm.cfg = system_load("config.lua")()
	 local factor = vppcm / 28.3687
	 for _,v in ipairs({
				 "border_width"
	 }) do
			wm.cfg[v] = math.ceil(wm.cfg[v] * factor)
	 end

	 -- send to all windows that the density has potentially changed
	 if (iter_windows) then
			for v in iter_windows(false) do
				 target_displayhint(v, 0, 0, TD_HINT_IGNORE, {ppcm = vppcm})
			end
	 end

	 mouse_cursor_sf(factor, factor)
end

function VRES_AUTORES(w, h, vppcm, _, source)
	 if (vppcm > 0 and math.abs(vppcm - VPPCM) > 1) then
			lunawm_update_density(vppcm)
	 end

	 if (video_displaymodes(source, w, h)) then
			resize_video_canvas(w, h)
			resize_image(wm.bg, w, h)
			wm.arrange()
	 end

end

wm.dump = function(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. wm.dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

wm.toboolean =  function(str)
	 local bool = false
	 if str == "true" then
			bool = true
	 end
	 return bool
end

lunawm_input = lunawm_normal_input
