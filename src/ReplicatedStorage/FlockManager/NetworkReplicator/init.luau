local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local config = require("./Config")
-- Packet will handle batching and compression for us
local packets = require("@self/Packets")
local packet = packets.sync
local moversFolder = script.Parent.Movers

local updateRate = 0.2

local serverParts = {} :: {BasePart}
local clientParts = {} :: {BasePart}

local inUse = false

local movers = {}

local HIDE_POS = Vector3.new(0,100000,0)

function loadMovers()
	for _,child in moversFolder:GetChildren() do
		movers[child.ClassName] = true
	end
end

function sync()
	local extractPositions = {} :: {Vector3}
	for i,part in serverParts do
		extractPositions[i] = part.CFrame 
	end
		
	local timeNow = workspace:GetServerTimeNow()
	if #Players:GetPlayers() < 1 then
		return
	end
	
	for i,_ in extractPositions do
		packet:Fire(clientParts[i],extractPositions[i],timeNow)
	end
end

function connect()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= updateRate then
			sync()
			elapsed = 0
		end
	end)
end

function removePart(part: BasePart?,destroy: boolean)
	local findIndex = table.find(serverParts,part)
	if not findIndex then return end
	if destroy then
		clientParts[findIndex]:Destroy()
		serverParts[findIndex]:Destroy()
		table.remove(serverParts,findIndex)
		table.remove(clientParts,findIndex)
		packets.removeObject:Fire(clientParts[findIndex],destroy)
	else
		serverParts[findIndex].Anchored = true
		clientParts[findIndex].Anchored = true
		serverParts[findIndex].CollisionGroup = "Default"
		clientParts[findIndex].CollisionGroup = "Default"
		
		table.remove(serverParts,findIndex)
		table.remove(clientParts,findIndex)
		packets.removeObject:Fire(clientParts[findIndex])
	end
end

--[[================================================================]]
-- interface

function cleanTheInside(part: BasePart)
	for _,child: Instance in part:GetDescendants() do
		if movers[child.Name] then
			child:Destroy()
		end
	end
end

function link(serverPart: BasePart, clientPart: BasePart)
	serverPart:SetNetworkOwner(nil)
	
	table.insert(serverParts,serverPart)
	table.insert(clientParts,clientPart)	
end 

-- pass in a client part to get its mirror on the server side
-- clientPart: anything that's not a parent of Camera
function mirrorToServer(clientPart: BasePart)
	local serverPart = clientPart:Clone()
	local parent = workspace.CurrentCamera
	
	clientPart:PivotTo(CFrame.new(HIDE_POS))
	cleanTheInside(clientPart)
	clientPart.Anchored = true
	
	serverPart.Parent = parent
	link(serverPart,clientPart)
	
	return serverPart
end

function mirrorToClient(serverPart: BasePart, newParent: Folder): BasePart
	local clientPart = serverPart:Clone()
	local parent = if (newParent and typeof(newParent) == "Instance") then newParent else workspace	

	clientPart:PivotTo(CFrame.new(HIDE_POS))
	cleanTheInside(clientPart)
	part.Anchored = true

	clientPart.Parent = parent
	link(serverPart,clientPart)
	
	return serverPart
end

function init()
	if inUse then
		return
	end
	
	-- expose to the client
	script:SetAttribute("rate",config.network.updateRate)
	script:SetAttribute("clientDelayMultiplier",config.network.clientDelayMultiplier)
	script.Receiver.Enabled = true
	
	connect()
	loadMovers()
	inUse = true
end

return {
	init = init,
	addShared = link,
	mirrorToClient = mirrorToClient,
	mirrorToServer = mirrorToServer,
	removePart = removePart
}