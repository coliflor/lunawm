-- variables.lua

local variables = {}

-- Example variable: gaps
variables.gaps = function(value)
    local gaps = tonumber(value)
    if gaps then
        print("Setting gaps to:", gaps)
				wm.cfg.window_gap =value
    else
        print("Invalid gaps value:", value)
    end
end

variables["gaps"] = variables.gaps

return variables
