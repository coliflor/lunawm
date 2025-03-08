-- Minimal Timer System

local timers = {}

local function process_timers()
    for i = #timers, 1, -1 do
        local timer = timers[i]
        timer.count = timer.count - 1
        if timer.count == 0 then
            local ok, err = pcall(timer.trigger)
            if not ok then print("Timer Error:", err) end
            if timer.once then
                table.remove(timers, i)
            else
                timer.count = timer.delay
            end
        end
    end
end

function awm_clock_pulse(...)
    process_timers()
    -- mouse_tick(1) -- If needed, call mouse_tick here.
end

function timer_add_periodic(name, delay, once, trigger)
	 local timer = {
			name = name,
			delay = delay,
			count = delay,
			once = once,
			trigger = trigger,
	 }
	 table.insert(timers, timer)
end

return {
    add_periodic = timer_add_periodic,
}
