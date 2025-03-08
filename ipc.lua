-- prio IPC system (adapted from Durden)
-- echo "variable gaps 10" | socat - UNIX-CONNECT:./Proyectos/awm/awm/ipc/awm_control

-- CURSED: i think the ipc system is causing stack dump have no idea why

local prio_ipc = {}
local clients = {}
local control_socket

local control_path = "awm_control" -- Default control path

local function update_control()
	 if (control_socket) then
			control_socket:close()
			control_socket = nil
	 end

	 for _, v in ipairs(clients) do
			v.connection:close()
	 end
	 clients = {}

	 if (control_path == ":disabled") then
			return
	 end

	 zap_resource("ipc/" .. control_path)
	 control_socket = open_nonblock("=ipc/" .. control_path)
end

-- Function to set the control path
prio_ipc.set_control_path = function(path)
	 control_path = path
	 update_control()
end

update_control() -- Initial control path setup

local function split(inputstr, sep)
	 if sep == nil then
			sep = "%s"
	 end
	 local t = {}
	 for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
			table.insert(t, str)
	 end
	 return t
end

local commands = {
	 variable = function(client, line, res, remainder)
			local parts = split(remainder, " ")
			if #parts >= 2 then
				 local var_name = parts[1]
				 local var_values = {}
				 for i = 2, #parts do
						table.insert(var_values, parts[i])
				 end
				 if wm.var and wm.var[var_name] then
						wm.var[var_name](unpack(var_values)) -- Pass all values to the variable's function
						return {"OK\n"}
				 else
						return {"EINVAL: variable not found.\n"}
				 end
			else
				 return {"EINVAL: invalid arguments for variable command.\n"}
			end
	 end,
	 exec = function(client, line, res, remainder)
			if (wm.actions and wm.actions[remainder]) then
				 wm.actions[remainder]()
				 return {"OK\n"}
			else
				 return {"EINVAL: target action not found.\n"}
			end
	 end
}

local function remove_client(ind)
	 local cl = clients[ind]
	 cl.connection:close()
	 table.remove(clients, ind)
end

local function do_line(line, cl)
	 local ind = string.find(line, " ")
	 local cmd, remainder

	 if (not ind) then
			cl.connection:write("EINVAL: missing command arg\n")
			return
	 end

	 cmd = string.sub(line, 1, ind - 1)
	 remainder = string.sub(line, ind + 1)

	 if not (commands[cmd]) then
			cl.connection:write("EINVAL: missing command\n")
			return
	 end

	 for _, v in ipairs(commands[cmd](cl, line, nil, remainder)) do
			cl.connection:write(v .. "\n")
	 end
end

local function poll_control_channel()
	 local nc = control_socket:accept()

	 if (nc) then
			local client = {
				 connection = nc,
				 seqn = #clients + 1 -- Unique sequence number
			}
			nc:lf_strip(true)

			nc:data_handler(function(gpublock)
            local line, ok = nc:read()
            while line do
							 do_line(line, client)
							 line, ok = nc:read()
            end
            if not ok then
							 local ind = nil
							 for i, v in ipairs(clients) do
									if v == client then
										 ind = i
										 break
									end
							 end
							 if ind then
									remove_client(ind)
							 end
            end
            return ok
			end)
			table.insert(clients, client)
	 end
end

timer_add_periodic("control", 1, false, function()
											if (control_socket) then
												 poll_control_channel()
											end
end, true)

return prio_ipc
