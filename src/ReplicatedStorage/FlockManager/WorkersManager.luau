local TableRegistry = game:GetService("SharedTableRegistry")

local config = require("./Config")
local t = require("./t")

type commands = "init" | "start"
type worker = Actor & {
	SendMessage: (Actor, topic: commands, name: string, ...any) -> (),
}

local m = {}
local actor = {}

local allWorkers : { worker }
local workersCount : number
local lastUsed = 1

function m.initActors()
	setup()
	for _, worker in allWorkers do
		worker:SendMessage("init")
	end
end

function m.giveTask(objectName,group, goal)
	if lastUsed > workersCount then
		lastUsed = 1
	end

	allWorkers[lastUsed]:SendMessage("start", objectName,group, goal)

	lastUsed += 1
end

--[[================================================================]]

function setup()
	local num = config.global.numberOfWorkers
	if script:FindFirstChildOfClass("Actor") then return end
	local template
	
	if not config.global.serverSide then
		template = script.Parent.WorkersTemplate.ClientActor
	else
		template = script.Parent.WorkersTemplate.Actor
	end
	
	for i=1, num do
		local newWorker = template:Clone()
		newWorker.Name ..= i
		newWorker.Parent = script
		newWorker.Worker.Enabled = true
	end
	
	allWorkers = script:GetChildren()
	workersCount = #allWorkers
	
	-- can't use the actor right after changing its parent
	task.wait()
end

--[[================================================================]]
-- Actor Data

local core
--local grid 

--local allCells = {}:: { [string]: string }

local privateConfig = {} :: t.privateConfig
local forcesList = {} :: { [string]: Vector3 } -- in privateConfig
local positionsList = {} :: { [string]: Vector3 } -- ...
local recoveryList = {} :: { [string]: number }
local unitsConfig = {} :: t.config

local allGoals = {} :: { [string]: Vector3 }

local results: SharedTableRegistry

function actor.init()
	core = require("./Core")

	results = TableRegistry:GetSharedTable("updated")

	forcesList = TableRegistry:GetSharedTable("forcesList")
	positionsList = TableRegistry:GetSharedTable("positionsList")
	recoveryList = TableRegistry:GetSharedTable("recoveryList")
	unitsConfig = TableRegistry:GetSharedTable("unitsConfig")
	--allCells = TableRegistry:GetSharedTable("allCells")
	allGoals = TableRegistry:GetSharedTable("allGoals")
end

function actor.excuteTask(name: string,group: {string}, goal: Vector3?)
	task.desynchronize()
	
	local config = unitsConfig[name]
	goal = allGoals[name] or goal
	
	privateConfig = {
		["positionsList"] = positionsList,
		["forcesList"] = forcesList,
		["unitsConfig"] = unitsConfig,
		["recoveryList"] = recoveryList,
	}
	
	
	local newVelocity = core.start(name,group, config, privateConfig, goal)
	results[name] = newVelocity
end

return {
	m = m,
	actor = actor,
}
