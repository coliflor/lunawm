-- variables.lua

local variables = {}

-- gaps
variables.gaps = function(value)
	 local gaps = tonumber(value)
	 if gaps then
			print("Setting gaps to:", gaps)
			wm.cfg.window_gap = gaps
	 else
			print("Invalid gaps value:", value)
	 end
	 arrange()
end

-- border
variables.border = function(value)
	 local border = tonumber(value)
	 if border then
			print("Setting border to:", border)
			wm.cfg.border_width = border
	 else
			print("Invalid border value:", value)
	 end
	 rebuild_all_decorations()
	 arrange()
end

-- statusbar_height
variables.statusbar_height = function(value)
	 local statusbar_height = tonumber(value)
	 if statusbar_height then
			print("Setting statusbar_height to:", statusbar_height)
			wm.cfg.statusbar_height = statusbar_height
	 else
			print("Invalid statusbar_height value:", statusbar_height)
	 end
	 arrange()
end

-- fuse_tags
variables.fuse_tags = function(tag_one, tag_two)
    local tone = tonumber(tag_one)
    local ttwo = tonumber(tag_two)

    if tone and ttwo then
        print("fusing tags:", tone, ttwo)
        fuse_tags(tone, ttwo)
				view_tag(tone)
    else
        print("Invalid tags to fuse", tone, ttwo)
    end
end

-- view tag
variables.view_tag = function(tag)
    local tone = tonumber(tag)

    if tone then
        print("fusing tags:", tone)
				view_tag(tone)
    else
        print("Invalid tag", tone)
    end
end

variables["gaps"] = variables.gaps
variables["border"] = variables.border
variables["statusbar_height"] = variables.statusbar_height
variables["fuse_tags"] = variables.fuse_tags
variables["view_tag"] = variables.view_tag

return variables
