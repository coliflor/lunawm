--
-- see actions.lua for bindable functions
--
-- For stateful keybindings, like C-W, C-G:
-- [M1 .. "W"] = "set_temp_prefix_1"
--
-- For triggering on release, add the suffix _f"
--
-- other assignable functions:
-- menu_path(name1/name2/name3...)
-- switch

-- https://github.com/letoram/arcan/blob/master/data/scripts/builtin/keyboard.lua

local M1 = "ralt_";
local M2 = "lalt_";
local M3 = "lalt_lctrl_";
return {
	 -- window positioning / sizing controls
	 [M2 ..    "j"] = "select_up",
	 [M2 ..    "k"] = "select_down",
	 [M2 ..    "h"] = "select_left",
	 [M2 ..    "l"] = "select_right",
	 [M3 ..    "j"] = "move_up",
	 [M3 ..    "k"] = "move_down",
	 [M3 ..    "h"] = "move_left",
	 [M3 ..    "l"] = "move_right",
	 [M3 ..    "m"] = "toggle_maximize",
	 [M1 ..    "a"] = "shrink_h",
	 [M1 ..    "s"] = "grow_h",
	 [M1 ..    "d"] = "shrink_w",
	 [M1 ..    "f"] = "grow_w",
	 [M3 ..   "UP"] = "assign_top",
	 [M3 .. "DOWN"] = "assign_bottom",
	 [M3 .. "LEFT"] = "assign_left",
	 [M3 .."RIGHT"] = "assign_right",

	 -- others
	 [M2 .. "m"] = "terminal",
	 [M2 .. "ESCAPE"] = "shutdown",
	 [M2 .. "TAB"] = "reset",
	 [M1 .. "v"] = "clipboard_paste",

	 -- Example keybindings
	 [M2 .. "1"] = "view_tag_1",  -- Switch to tag 1
	 [M2 .. "2"] = "view_tag_2",  -- Switch to tag 2
	 [M2 .. "j"] = "focus_next", -- Focus next window
	 [M2 .. "k"] = "focus_prev", -- Focus previous window
	 [M2 .. "q"] = "destroy_active_window", -- Close window
	 [M2 .. "z"]  = "drag_window", -- Drag Window

	 [M2 .. "y"] = "cycle_layout",
	 [M2 .. "k"] = "rotate_window_stack",
	 [M2 .. "j"] = "rotate_window_stack_negative",
	 [M2 .. "z"] = "swap_master",
};
