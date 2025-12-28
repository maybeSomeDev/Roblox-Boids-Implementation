local flockModule = game.ReplicatedStorage.FlockManager
local flockManager = require(flockModule)
local config = require(flockModule.Config)

function new()
	local newManager = flockManager.new(config.testFile)

	local birds: { BasePart } = workspace.Birds:GetChildren()

	newManager:add(birds, config.testFile)
	
	newManager:start()
end

if script:GetAttribute("spawn") then new() end

game.UserInputService.InputBegan:Connect(function(obj)
	if obj.KeyCode == Enum.KeyCode.H then
		script:SetAttribute("spawn",not script:GetAttribute("spawn"))
	end
end)

script.AttributeChanged:Connect(new)