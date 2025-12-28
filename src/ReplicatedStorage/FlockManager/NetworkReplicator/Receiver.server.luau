local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packet = require("./Packets")

local networkLink = script.Parent

-- stored objects/parts and their snapshots
local lastUpdate = {}:: {
	[Part]: {snapshot}
}

local animTime = 0.2
local syncedTime = -1

type snapshot = {
	_time: number,
	_goal: CFrame
}

local running = nil

function cleanOldSnapshots(object,fromIndex: number)
	if not object then
		return
	end
	if not lastUpdate[object] then
		return
	end
	
	local snapshots = lastUpdate[object]
	for index=fromIndex,1,-1 do
		local data = snapshots[index]

		if data and syncedTime - data._time > 1.5 then
			table.remove(snapshots,index)
		end
	end
end

function interpolate()
	if running then
		return
	end
	
	RunService.Heartbeat:Connect(function(dt)
		syncedTime = workspace:GetServerTimeNow()
		local currentTime = syncedTime - animTime

		for object, snapshots in lastUpdate do
			-- user want to see the raw data
			if animTime <= 0 then
				local last = snapshots[#snapshots]
				if not last then
					continue
				end
				
				object.CFrame = last._goal
				cleanOldSnapshots(object,#snapshots)
			end
			
			local lastActive: number? = nil
			if #snapshots <= 1 then
				continue
			end
			
			-- this is faster than starting from the oldest(first) snapshot
			for index = #snapshots, 1, -1 do
				local currentData = snapshots[index - 1] --left
				local nextData = snapshots[index]
				if not currentData then
					break
				end
				
				-- if current time is between 2 snapshots
				if currentData._time <= currentTime and nextData._time >= currentTime then
					lastActive = index
					local currentPos = currentData._goal
					local nextPos = nextData._goal

					local duration = (nextData._time - currentData._time)
					local elapsed = (currentTime - currentData._time)
					local alpha = math.clamp(elapsed/duration,0,1)
					
					object:PivotTo(currentPos:Lerp(nextPos,alpha)) 
					break
				end
			end

			if lastActive then
				cleanOldSnapshots(object,lastActive)
			end
		end
	end)
end

function addSnapshot(object, pos, timeNow)
	if not lastUpdate[object] then
		lastUpdate[object] = {}
	end
	
	for i,v in lastUpdate[object] do
		if v._time > timeNow then
			table.insert(lastUpdate[object],i,{
				_goal = pos,
				_time = timeNow
			})
			return
		end
	end
	
	table.insert(lastUpdate[object],{
		_goal = pos,
		_time = timeNow
	})
end

function sync(object: BasePart?, position: CFrame, timeNow: number, _delay: number)
	if not object then
		return
	end
	if script:GetAttribute("disable") then
		return
	end
	if not running then
		animTime = networkLink:GetAttribute("rate") * networkLink:GetAttribute("clientDelayMultiplier")
		interpolate()
		running = true
	end
	
	addSnapshot(object,position,timeNow)
end

function remove(object: BasePart?,destroy: boolean?)
	
	if lastUpdate[object] then
		task.spawn(function() -- not sure if this is needed
			cleanOldSnapshots(object,#lastUpdate[object])
		end)
		lastUpdate[object] = nil
	end
	if object and destroy then
		object:Destroy()
	end
end

packet.sync.OnClientEvent:Connect(sync)
packet.removeObject.OnClientEvent:Connect(remove)