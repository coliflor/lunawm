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

local M1 = "ralt_"
local M2 = "lalt_"
local M3 = "lalt_lctrl_"
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
	 [M3 .. "TAB"] = "reset",
	 [M1 .. "v"] = "clipboard_paste",

	 --
	 [M2 .. "q"] = "view_tag_1",
	 [M2 .. "w"] = "view_tag_2",
	 [M2 .. "e"] = "view_tag_3",
	 [M2 .. "r"] = "view_tag_4",
	 [M2 .. "t"] = "view_tag_5",

	 [M2 .. "TAB"] = "swap_last_current_tag",

	 [M3 .. "q"] = "move_window_to_tag_1",
	 [M3 .. "w"] = "move_window_to_tag_2",
	 [M3 .. "e"] = "move_window_to_tag_3",
	 [M3 .. "r"] = "move_window_to_tag_4",
	 [M3 .. "t"] = "move_window_to_tag_5",

	 [M2 .. "1"] = "assign_tag_1",
	 [M2 .. "2"] = "assign_tag_2",
	 [M2 .. "3"] = "assign_tag_3",
	 [M2 .. "4"] = "assign_tag_4",
	 [M2 .. "5"] = "assign_tag_5",

	 [M2 .. "p"] = "destroy_active_window", -- Close window

	 [M2 .. "f"] = "toggle_maximize",
	 [M2 .. "y"] = "cycle_layout",
	 [M2 .. "k"] = "rotate_window_stack",
	 [M2 .. "j"] = "rotate_window_stack_negative",
	 [M2 .. "l"] = "decrease_master_width",
	 [M2 .. "h"] = "increase_master_width",
	 [M2 .. "z"] = "swap_master",

	 [M2 .. "b"] = "swap_child_windows",
	 [M2 .. "v"] = "swap_child_windows_negative",

	 [M2 .. "x"] = "fuse_all_tags",
};
