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

variables["gaps"] = variables.gaps
variables["border"] = variables.border
variables["statusbar_height"] = variables.statusbar_height

return variables
