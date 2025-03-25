return {

	 default_layout_mode = "master_stack", -- monocle, grid, master_stack, middle_stack, floating

	 num_tags = 5; -- Number of workspaces/tags
	 default_master_ratio = 0.6; -- Ratio of master window size

	 conn_point = "lunawm",

	 --
	 window_gap_top = 40,
	 window_gap_bottom = 40,
	 window_gap_left = 40,
	 window_gap_right = 40,

	 -- input tuning
	 keymap = "default.lua",
	 drag_resize_inertia = 8,
	 repeat_period = 100, -- ticks between press/release
	 repeat_delay = 300, -- delay before feature is enabled

	 -- mouse control
	 mouse_cursor_scale = 1.0,
	 mouse_input_scale_x = 1.0,
	 mouse_input_scale_y = 1.0,

	 background = "img/lunawm.png", -- will load/stretch if found
	 animation_speed = 0,
	 global_gain = 1.0,

	 -- external programs
	 terminal_font = {"hack.ttf", "emoji.ttf"},
	 terminal_font_sz = 10 * FONT_PT_SZ,
	 terminal_hint = 2, -- 0: off, mono, light, normal
	 terminal_cfg = "palette=solarized-black:bgalpha=190:"; -- END with :
	 default_font = {"fonts.ttf", "emoji.ttf"},
	 default_font_sz = 12 * FONT_PT_SZ,

	 -- selection region
	 select_color = {0, 255, 0},
	 select_opacity = 0.8,

	 -- default window behavior
	 force_size = true,

	 -- window visuals
	 window_gap = 10;
	 border_width = 10,
	 border_alpha = 0.8,
	 active_color = {252, 194, 110},
	 inactive_color = {45, 43, 83},

	 debug_mode = true,
}
