local m = {}

local config = require("./Config")

local grid = {}
local closestGrid = {}
local cellSize = config.global.gridCellSize
local nearbyCellsOffset = {}

type positions = {[string]: Vector3 | CFrame}
type groupPos = {[string]: {positions}}

function generateOffsets()
	for x= -1,1,1 do
		for y= -1,1,1 do
			for z= -1,1,1 do
				table.insert(nearbyCellsOffset,Vector3.new(x,y,z) * cellSize)
			end
		end
	end
end

function m.getVectorGridCell(pos: Vector3): Vector3
	assert(typeof(pos) == "Vector3","passed value is not a 'Vector3': "..typeof(pos))

	local x = math.floor(pos.X / cellSize) * cellSize
	local y = math.floor(pos.Y / cellSize) * cellSize
	local z = math.floor(pos.Z / cellSize) * cellSize

	return Vector3.new(x,y,z)
end

function m.vectorToString(vec: Vector3): string
	if typeof(vec) ~= "Vector3" then
		warn("passed value is not a 'Vector3': "..typeof(vec))
		return
	end
	
	return `{vec.X},{vec.Y},{vec.Z}`
end

function m.stringToVector(str: string): Vector3?
	if typeof(str) ~= "string" then
		warn("passed value is not a 'string': "..typeof(str))
		return
	end

	local split = str:split(",")

	if #split ~= 3 then
		warn("incorrec size",#split)
		return nil
	end
	for i,v in split do
		if not tonumber(v) then
			warn("not a valid number")
			return nil
		end
	end

	return Vector3.new(split[1],split[2],split[3])
end 

function m.getNearby(vec: Vector3, stringType: boolean): {string | Vector3}
	local collected = table.create(27)
	for i, offset: Vector3 in nearbyCellsOffset do
		local new = vec + offset
		
		if stringType then
			new = m.vectorToString(new)
		end
		table.insert(collected,new)
	end
	return collected
end

function m.groupPositions(positions: positions, isCFrame: boolean): groupPos
	local group = {}
	
	for name,pos in positions do
		pos = if isCFrame then pos.Position else pos
		
		local cell = m.getVectorGridCell(pos)
		cell = m.vectorToString(cell)
		
		if not group[cell] then
			group[cell] = {}
		end
		
		table.insert(group[cell],name)
	end
	
	return group
end

generateOffsets()

return m