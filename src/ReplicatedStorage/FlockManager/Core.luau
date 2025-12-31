local utils = require("./Utils")
local t = require("./t")

-- TODO: add a (steer) function
-- TODO: remove the tables in (start)

type modeResult = {
	dir: Vector3,
	count: number,
}

type modeNames = "avoid" | "cohesion" | "align" | "avoidObs"

-- no need for types, the name is clear enough
function getAvoidance(distance, difference, config): modeResult?
	if distance <= config.avoidRadius then
		-- push harder the close we're to another bird
		local strength = config.avoidRadius / distance
		local weight = difference.Unit * strength

		return {
			dir = weight,
			count = 1,
		}
	end

	return nil
end

function getCohesion(distance, otherPos, config): modeResult?
	if distance <= config.centerRadius then
		local dir = otherPos

		return {
			dir = dir,
			count = 1,
		}
	end
	return nil
end

function getAlign(other, distance, config, privateConfig: t.privateConfig): modeResult?
	if distance <= config.alignRadius then
		local dir = privateConfig.forcesList[other]

		return {
			dir = dir,
			count = 1,
		}
	end

	return nil
end

function inSight(difference, lookVector, config): boolean
	if config.fov then
		-- flipped to point from self to other
		-- the original diff Dir is from other to self
		local fovDir = -difference.Unit
		if fovDir:Dot(lookVector) < config.fov then
			return false 
		end
	end

	return true
end

function hasRecovered(me, config: t.config, privateConfig: t.privateConfig): boolean
	-- if still in recoveryTime, return false
	if (os.clock() - privateConfig.recoveryList[me]) < config.recoveryTime then return false end

	return true
end

function start(
	me: string,
	group: t.manager,
	config: t.config,
	privateConfig: t.privateConfig,
	goal: Vector3?
): Vector3

	local myPos = privateConfig.positionsList[me].Position
	local myCF: CFrame = privateConfig.positionsList[me]
	local myVelocity = privateConfig.forcesList[me]

	local blockedPath = false
	--[[================================================================]]
	-- Helpers
	local allModesInfo = {} :: { [string]: modeResult }
	local allIntensities = {
		avoid = config.avoidIntensity,
		align = config.alignIntensity,
		cohesion = config.cohesionIntensity,
		avoidObs = config.avoidObstaclesIntensity,
	}

	-- local functions because I need them to change the outer scope
	local function update(name: modeNames, info: modeResult)
		if not info then return end

		if not allModesInfo[name] then
			allModesInfo[name] = {}
			allModesInfo[name] = info
			return
		end

		local modeInfo = allModesInfo[name]
		for index, value in info do
			modeInfo[index] += value
		end
	end

	-- for modes that have more than one direction/target
	local function applyWeights()
		for name, mode in allModesInfo do
			if name == "avoidObs" then continue end
			if mode.count <= 1 then continue end

			mode.dir /= mode.count

			if blockedPath then continue end
			if name == "cohesion" then 
				mode.dir = mode.dir - myPos 
			end

			if mode.dir.Magnitude > 0 then 
				mode.dir = mode.dir.Unit 
			end
		end
	end

	local function applyIntensities()
		local total = Vector3.zero

		for name, mode in allModesInfo do
			if not mode.dir then continue end
			if blockedPath and name ~= "avoidObs" then continue end

			local newDir = (mode.dir * allIntensities[name])
			total += newDir
		end
		return total
	end

	local function clearAllBut(exclude: { modeNames })
		for i, v in allModesInfo do
			if table.find(exclude, i) then continue end
			allModesInfo[i] = nil
		end
	end

	--[[================================================================]]

	local obsDir 

	if config.enableObstacleAvoidance then
		obsDir = utils.findPath(
			myPos,
			config.obstacleRayLength * config.speed,
			myVelocity,
			myCF,
			me
		)
	end

	debug.profilebegin("Apply Rules")
	if obsDir then
		blockedPath = true
		local _info = {
			dir = obsDir,
			count = 1,
		} :: modeResult

		privateConfig.recoveryList[me] = os.clock()
		update("avoidObs", _info)
	end

	for _, boid: string in group do
		if boid == me then continue end
		local otherPos = privateConfig.positionsList[boid].Position
		local distance, difference = utils.distance(myPos, otherPos)
		if not (distance > 0.01) then continue end
		debug.profilebegin("basic rules")
		local avoidResult = getAvoidance(distance, difference, config)
		update("avoid", avoidResult)
		-- Bird is busy trying to not get hit
		if not hasRecovered(me, config, privateConfig) then
			debug.profileend()
			continue
		end
		--if not inSight(difference,lookVector,config) then continue end

		local cohesionResult = getCohesion(distance, otherPos, config)
		update("cohesion", cohesionResult)

		local alignResult = getAlign(boid, distance, config, privateConfig)
		update("align", alignResult)
		debug.profileend()
	end

	applyWeights()
	if blockedPath then
		clearAllBut({ "avoidObs"})
	end
	local finalVelocity: Vector3 = applyIntensities()

	if goal and hasRecovered(me, config, privateConfig) and not blockedPath then
		local _, goalDir = utils.distance(goal, myPos)
		finalVelocity += goalDir.Unit * config.goalIntensity
	end

	-- NAN / INF
	if not utils.verifyVector(finalVelocity) then
		finalVelocity = myCF.LookVector
	end

	if blockedPath then
		debug.profileend()
		return finalVelocity.Unit
	end
	finalVelocity = (myVelocity + finalVelocity).Unit
	debug.profileend()
	
	return finalVelocity
end

return {
	["start"] = start,
}
