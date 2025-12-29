local part = script.Parent
local startingPos = part.Position

local radius = 60
local yRadius = radius/4

while task.wait(2.5) do
	part.Position = startingPos + Vector3.new(
		math.random(-radius,radius),
		math.random(-yRadius,yRadius),
		math.random(-radius,radius)
	)	
end