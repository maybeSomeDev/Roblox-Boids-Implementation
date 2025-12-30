--!nocheck
-- Manager

local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local TableRegistry = game:GetService("SharedTableRegistry")

local manager = {}
manager.__index = manager

-- local core = require("@self/Core")
local utils = require("@self/Utils")
local config = require("@self/Config")
local grid = require("@self/Grid")
local workersManager = require("@self/WorkersManager").m
local networkReplicator = require("@self/NetworkReplicator")

local t = require("@self/t")

local allUnits = {} :: { [string]: t.unit }
local allCells = {} :: { [string]: typeof(allUnits) }

local canReplicate = (config.network.enable and config.global.serverSide)

--[[================================================================]]

local staticGoals = {} :: { [string]: Vector3 }
local dynamicGoals = {} :: { [string]: () -> (Vector3) }

local positionsList = {} :: { [string]: Vector3 }
local unitsConfig = {} :: t.config

local sharedForces: SharedTable = nil :: { [string]: Vector3 }
local sharedPositions: SharedTable = nil :: { [string]: Vector3 }
local sharedRecovery: SharedTable = nil :: { [string]: number }
local sharedConfig: SharedTable = nil :: { [string]: t.config }
--local sharedCells: SharedTable = nil :: { [string]: {} }

local sharedGoals: SharedTable = nil :: { [string]: Vector3 }

local updatedVelocites = SharedTable.new({})
TableRegistry:SetSharedTable("updated", updatedVelocites)

--[[================================================================]]
-- init
function registerAll()
	sharedForces = SharedTable.new()
	sharedPositions = SharedTable.new()
	sharedRecovery = SharedTable.new()
	sharedConfig = SharedTable.new()
	--sharedCells = SharedTable.new()
	sharedGoals = SharedTable.new()
	
	TableRegistry:SetSharedTable("forcesList", sharedForces)
	TableRegistry:SetSharedTable("positionsList", sharedPositions)
	TableRegistry:SetSharedTable("recoveryList", sharedRecovery)
	TableRegistry:SetSharedTable("unitsConfig", sharedConfig)
	--TableRegistry:SetSharedTable("allCells", sharedCells)
	TableRegistry:SetSharedTable("allGoals", sharedGoals)
end

function initCollisionGroup()
	if RunService:IsServer() then
		local collName = config.global.flockCollisionGroup
		PhysicsService:RegisterCollisionGroup(collName)
		PhysicsService:CollisionGroupSetCollidable(collName, collName,false)
	end
end

function new(config)
	local self = {
		["connections"] = {},
		["group"] = {},
		["config"] = config,
	} :: t.manager

	return setmetatable(self, manager)
end

type manager = typeof(new(...))

--[[================================================================]]

function manager.add(self: manager, objects: { t.unit }, unitConfig: t.config?)
	-- convert to table
	local convert: { t.unit } = if typeof(objects) == "table" then objects else { objects }
	unitConfig = unitConfig or self.config

	for _, clientUnit in convert do
		local name = clientUnit.Name
		local serverUnit = clientUnit
		if canReplicate then
			serverUnit = networkReplicator.mirrorToServer(clientUnit)
		end
		local clientConnection
		local serverConnection

		if serverUnit then
			serverConnection = serverUnit.Destroying:Once(function()
				if clientConnection then
					clientConnection:Disconnect()
					clientConnection = nil
				end
				self:remove(name,true)
			end)
		end

		clientConnection = clientUnit.Destroying:Once(function()
			if serverConnection then
				serverConnection:Disconnect()
				serverConnection = nil
			end
			self:remove(name,true)
		end)

		allUnits[name] = serverUnit

		table.insert(self.group,name)
		unitsConfig[name] = unitConfig
		sharedConfig[name] = unitConfig
	end

	return self
end

local steps = math.clamp(config.global.updateFrequency, 1, 60)

function manager.start(self: manager)
	manager.firstRun = true
	updatePrivateConfig(self)

	workersManager.initActors()
	
	-- TODO:
	local _tick = 1
	local connection = RunService.Stepped:Connect(function()
		if (_tick % steps) == 0 then
			updatePrivateConfig(self)
			collect(self)
		end
		_tick += 1
	end)
	
	local _updateTick = 1
	local updateConnection = RunService.Heartbeat:Connect(function()
		if (_updateTick % (steps)) == 0 then
			apply(self)
		end
		_updateTick += 1
	end)
	
	table.insert(self.connections, connection)
	table.insert(self.connections, updateConnection)
end

function updatePrivateConfig(self: manager)
	debug.profilebegin("update birds info")
	-- init values, they'll get updated somewhere else depending on the data
	if manager.firstRun then
		for _, name: string in self.group do -- private config
			local getObject: t.unit = allUnits[name]
			if not getObject then return end

			sharedPositions[name] = getObject.CFrame
			sharedForces[name] = getObject.LinearVelocity.VectorVelocity
			if sharedRecovery[name] == nil then 
				sharedRecovery[name] = -1
			end		
		end
	end
	
	for name,goal in staticGoals do
		sharedGoals[name] = goal
		staticGoals[name] = nil
	end
	
	if self.getGoal then
		self._goal = self.getGoal()
	end
	
	for name,updater in dynamicGoals do
		sharedGoals[name] = updater()
	end
	
	positionsList = sharedPositions
	allCells = grid.groupPositions(positionsList,true)
	--SharedTable.clear(sharedCells)
	--for i,v in allCells do
	--	sharedCells[i] = v
	--end

	debug.profileend()
end

function updateVelocity(name: string, newVelocity: Vector3)
	local object = getObjectByName(name)
	local getConfig: t.config = getObjectConfig(name)
	local speed = getConfig.speed

	newVelocity = newVelocity * speed
	object.LinearVelocity.VectorVelocity = newVelocity

	local newRotation = CFrame.new(object.Position, object.Position + newVelocity.Unit)
	object.CFrame = newRotation
	sharedPositions[name] = newRotation
	sharedForces[name] = newVelocity
end

-- the last firewall/check before updating the velocity
function _update(name: string, velocity: Vector3)
	if not name or typeof(name) ~= "string" then return end

	if not getObjectByName(name) then return end

	if not utils.verifyVector(velocity) then return end

	updateVelocity(name, velocity)
end

function apply(self: manager)
	debug.profilebegin("update Velocity")
	for name, velocity in updatedVelocites do
		_update(name, velocity)
	end
	if manager.firstRun then
		manager.firstRun = false
	end
	debug.profileend()
end

function collect(self: manager)
	local myGroup = {}

	for _, name: string in self.group :: t.group do	
		debug.profilebegin("collecting groups")
		table.clear(myGroup)
		
		debug.profilebegin("get nearby")
		local myCell = grid.getVectorGridCell(positionsList[name].Position)
		
		-- get nearby cells 
		local nearbyCells = grid.getNearby(myCell,true)
		debug.profileend()
		-- get birds in nearby cells
		for _,vec in nearbyCells do
			if allCells[vec] then
				for _,name in allCells[vec] do
					table.insert(myGroup,name)
				end
			end
		end

		debug.profileend()

		workersManager.giveTask(name, myGroup,self._goal)
	end
end

--[[================================================================]]
-- private utils
function getObjectByName(name: string): t.unit
	return allUnits[name]
end

function getObjectConfig(name: string): t.config
	return unitsConfig[name]
end

--[[================================================================]]
-- interface
function manager.addStaticGoal(self: manager,goal: Vector3, name: string?)
	if name then
		staticGoals[name] = goal
	else
		self._goal = goal
	end
end

function manager.addDynamicGoal(self: manager,getGoal: () -> (Vector3), name: string?)
	if name then
		dynamicGoals[name] = getGoal
	else
		self.getGoal = getGoal
	end
end

function manager.removeGoal(self: manager, name: string?)
	if name then
		removeFrom(sharedGoals,name)
		removeFrom(staticGoals,name)
		removeFrom(dynamicGoals,name)
	else
		self._goal = nil
		self.getGoal = nil
	end
end

function removeFrom(t, name)
	if t[name] then
		t[name] = nil
	end
end

function manager.pause(self: manager)
	if not self.connections then
		return
	end
	for _,conn in self.connections do
		conn:Disconnect()
	end
end

-- remove a bird
function manager.remove(self: manager, name: string, destroy: boolean?)
	if not name or typeof(name) ~= "string" then
		warn("passed arg (name) is not a string:",typeof(name))
		return
	end
	local unit = getObjectByName(name)
	removeFrom(allUnits,name)
	removeFrom(positionsList,name)
	removeFrom(unitsConfig,name)
	
	removeFrom(sharedPositions,name)
	removeFrom(sharedForces,name)
	removeFrom(sharedRecovery,name)
	removeFrom(sharedConfig,name)
	
	self:removeGoal(name)
	local index = table.find(self.group,name)
	if index then
		table.remove(self.group,index)
	end
	if canReplicate then
		networkReplicator.removePart(unit, destroy)
	else
		unit:Destroy()
	end
end

function manager.clean(self: manager, destroy: boolean?)
	self:pause()

	for _,name in self.group do
		self:remove(name,destroy)
	end
	
	self._goal = nil
	self._getGoal = nil
end

registerAll()
initCollisionGroup()

if config.network.enable then
	networkReplicator.init()	
end

return {
	new = new,

	getObjectByName = getObjectByName,
	getConfigByName = getObjectConfig
}