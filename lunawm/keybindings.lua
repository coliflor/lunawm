--
-- see actions.lua for bindable functions
--
-- For stateful keybindings, like C-W, C-G:
-- [M1 .. "W"] = "set_temp_prefix_1"
--
-- For triggering on release, add the suffix _f"

-- https://github.com/letoram/arcan/blob/master/data/scripts/builtin/keyboard.lua
-- local M2 = "lmeta_"
-- local M3 = "lmeta_lctrl_"
local M2 = "lalt_"
local M3 = "lalt_lctrl_"
return {
	 -- window positioning / sizing controls
	 [M3 .. "j"] = "move_up",
	 [M3 .. "k"] = "move_down",
	 [M3 .. "h"] = "move_left",
	 [M3 .. "l"] = "move_right",
	 [M3 .. "a"] = "shrink_h",
	 [M3 .. "s"] = "grow_h",
	 [M3 .. "d"] = "shrink_w",
	 [M3 .. "f"] = "grow_w",

	 [M3 .. "f"] = "toggle_maximize",
	 [M2 .. "f"] = "toggle_fullscreen",

	 [M2 .. "6"] = "assign_top",
	 [M2 .. "7"] = "assign_bottom",
	 [M2 .. "8"] = "assign_left",
	 [M2 .. "9"] = "assign_right",

	 [M3 .. "6"] = "fassign_top",
	 [M3 .. "7"] = "fassign_bottom",
	 [M3 .. "8"] = "fassign_left",
	 [M3 .. "9"] = "fassign_right",

	 -- others
	 [M2 .. "p"] = "terminal",
	 [M2 .. "ESCAPE"] = "shutdown",
	 [M3 .. "TAB"] = "reset",
	 [M2 .. "v"] = "paste",
	 [M2 .. "c"] = "copy",

	 -- tag manipulation
	 [M2 .. "a"] = "cycle_tags_negative",
	 [M2 .. "s"] = "cycle_tags",

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

	 [M2 .. "x"] = "fuse_all_tags",

	 --
	 [M2 .. "z"] = "destroy_active_window", -- Close window

	 [M2 .. "y"] = "reset_layout",
	 [M2 .. "u"] = "cycle_layout",
	 [M3 .. "u"] = "cycle_layout_negative",
	 [M2 .. "k"] = "rotate_window_stack",
	 [M2 .. "j"] = "rotate_window_stack_negative",
	 [M2 .. "l"] = "decrease_master_width",
	 [M2 .. "h"] = "increase_master_width",
	 [M2 .. "m"] = "swap_master",

	 [M2 .. "n"] = "swap_child_windows",
	 [M3 .. "n"] = "swap_child_windows_negative",

	 [M2 .. "g"] = "window_stacked",
	 [M3 .. "g"] = "window_floating",
	 [M2 .. "d"] = "center_window",
};
