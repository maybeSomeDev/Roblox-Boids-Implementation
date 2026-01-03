local m = {}

--[[================================================================]]
-- global configs ( please don't remove )

m.global = {
	serverSide = true,
	-- Numbers of frames to skip ( 0 = update the boids every frame )
	updateFrequency = 0,
	-- the cell size multiplied by 3 must be >= to the bird's biggest Radius
	gridCellSize = 15,
	-- Recommended: 15-30
	-- Min-Max: 5-300
	generatedDirectionCount = 30, -- maybe 'numberOfRays' is a better name
	numberOfWorkers = 16, -- /Actors
	
	flockCollisionGroup = "flockObjects"
}

m.network = {
	enable = true,
	updateRate = 0.15,
	clientDelayMultiplier = 2.1,
}

--[[================================================================]]
-- birds configs, you can store/move those to any other place

m.testFile = {
	speed = 25,

	avoidRadius = 6,
	alignRadius = 35,
	cohesionRadius = 45,

	avoidIntensity = 2,
	alignIntensity = 1.5,
	cohesionIntensity = 1.2,

	goalIntensity = 7,
	
	enableObstacleAvoidance = true,
	avoidObstaclesIntensity = 10,
	-- hitting an obstacle makes the bird ignore all rules other than Avoidance and ObstacleAvoidance
	-- to focus only on not hitting its head
	recoveryTime = 0.1, -- seconds
	-- Multiplier: speed * obstacleRayLength = real RayLength
	obstacleRayLength = 2,
}

return m