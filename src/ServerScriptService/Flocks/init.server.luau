local flockModule = game.ReplicatedStorage.FlockManager
local flockManager = require(flockModule)
local config = require(flockModule.Config)
local goal = workspace:FindFirstChild("Goal")

function new()
	local manager = flockManager.new(config.testFile)

	local birds: { BasePart } = workspace.Birds:GetChildren()

	local newGroup = {}
	
	for i= #birds,#birds - 10,-1 do
		birds[i].BrickColor = BrickColor.new("Bright yellow")
		birds[i].Material = Enum.Material.Neon
		table.insert(newGroup,birds[i])
		table.remove(birds,i)
	end
	manager:add(birds, config.testFile)

	local youngManager = flockManager.new(config.testFile)
	youngManager:add(newGroup)
	youngManager:start()

	youngManager:addDynamicGoal(function()
		return goal.Position
	end)

	manager:start()
end

if script:GetAttribute("spawn") then new() end

script.AttributeChanged:Connect(new)