local RESET_TIME = 0.35
local defColor = BrickColor.new("Pastel blue-green")
local hitColor = BrickColor.new("Persimmon")
task.wait(0.5)
local globalConfig = require(game.ReplicatedStorage.FlockManager.Config).global

local _params = RaycastParams.new()
_params.CollisionGroup = globalConfig.flockCollisionGroup

local cdList = {}:: {[BasePart]: number}

function resetColor()
	while task.wait(0.2) do
		for i,v in cdList do
			if (os.clock() - v) > RESET_TIME then
				cdList[i] = nil
				i.BrickColor = defColor
			end
		end
	end
end

task.spawn(resetColor)

for i,v: BasePart in script.Parent:GetChildren() do
	if v:IsA("BasePart") then
		v.Touched:Connect(function(hit)			
			cdList[v] = os.clock()
			v.BrickColor = hitColor
		end)
	end
end