local manager = require("../").actor
local actor = script.Parent

-- workers should do the bare minimum
-- they shouldn't care about the type of work they'll do, or how to do it
actor:BindToMessage("init",function(...)
	manager.init(...)
end)

actor:BindToMessage("update",function(...)
	manager.update(...)	
end)

actor:BindToMessage("start",function(...)
	manager.excuteTask(...)	
end)