local m = {}

local config = require("./Config")
local globalConfig = config.global

local directions = {} :: { Vector3 }

local _params = RaycastParams.new()
_params.CollisionGroup = globalConfig.flockCollisionGroup

-- generate sphere-shaped directions
-- source of the source: https://stackoverflow.com/questions/9600801
function generateDirections()
	local count = globalConfig.generatedDirectionCount

	local goldenRatio = (1 + math.sqrt(5)) / 2
	local angleIncrement = math.pi * 2 * goldenRatio

	for i = 1, count, 1 do
		local t = i / count
		local inclination = math.acos(1 - 2 * t)
		local azimuth = angleIncrement * i

		local x = math.sin(inclination) * math.cos(azimuth)
		local y = math.sin(inclination) * math.sin(azimuth)
		local z = math.cos(inclination)
		directions[i] = Vector3.new(x, y, z)
	end
	return directions
end

-- the directions are originally generated from the back to the front
function reverseSortDirections()
	local new = {}
	for i = #directions, 1, -1 do
		table.insert(new, directions[i])
	end
	directions = new
end

function m.distance(v1: Vector3, v2: Vector3): (number, Vector3)
	local difference = (v1 - v2)
	return difference.Magnitude, difference
end

function m.verifyVector(vec)
	if not vec or vec ~= vec or not (math.abs(vec.X) < math.huge) then
		return false
	end
	
	return true
end

function m.findPath(
	origin: Vector3,
	rayLength: number,
	velocity: Vector3,
	cf: CFrame,
	name
)
	debug.profilebegin("findPath")
	local shortRay = rayLength * 0.5

	local rayResult = workspace:Spherecast(origin, 3, velocity.Unit * rayLength, _params)

	if rayResult then
		local clearPath = false
		for _, dir in directions do
			local _dirTransform = cf:VectorToWorldSpace(dir)
			local ray = workspace:Raycast(origin, _dirTransform * rayLength, _params)

			-- found a clear new path
			if not ray then
				-- but does it fit?
				local tightPath = workspace:Spherecast(origin, 3, _dirTransform * shortRay, _params)
				if not tightPath then
					clearPath = _dirTransform
					break
				end
			end
		end
		debug.profileend()
		return if clearPath then clearPath else rayResult.Normal
	end

	debug.profileend()
	return nil
end

generateDirections()
reverseSortDirections()

return m