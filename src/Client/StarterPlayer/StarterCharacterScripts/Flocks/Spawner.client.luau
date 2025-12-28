--!nocheck
local bird = script.Bird

type bird = typeof(bird)

local spawned = {} :: { bird }
local config = require(game.ReplicatedStorage.FlockManager.Config)
local spawnPos = workspace.spawner.Position
local count = script:GetAttribute("count")
local radius = script:GetAttribute("radius")
local speed = config.testFile.speed

local tooClose = 0

function reset()
	for _, object: Part in spawned do
		applySettings(object)
	end

	if tooClose >= 10 then warn("Birds spawned too close:", tooClose) end
	script.Parent:SetAttribute("spawn", not script.Parent:GetAttribute("spawn"))
end

function new(object: Part)
	for i = 1, count do
		local newBird: bird = object or bird:Clone()
		newBird.Name = "bird" .. i
		spawned[i] = newBird
		newBird.Parent = workspace.Birds
		applySettings(newBird)
	end
	script.Parent:SetAttribute("spawn", not script.Parent:GetAttribute("spawn"))
end

function applySettings(new: bird, tries: number)
	local force = Vector3.new(math.random(-1, 1) + 0.3, 0, math.random(-1, 1) + 0.3)

	new.LinearVelocity.VectorVelocity = force.Unit * speed

	new.Position = spawnPos
	new.Position += Vector3.new(math.random(-radius, radius), 0, math.random(-radius, radius))
end

new()

workspace.AttributeChanged:Connect(function(att)
	if att == "reset" then
		reset()
	end
end)