export type unit = Part & {
	["LinearVelocity"]: LinearVelocity, -- child
}

export type manager = {
	group: group,
	config: config,
	_goal: Vector3?,
}

export type group = {
	-- name of the object, used to access its info (from privateConfig)
	-- or to access the object itself (unit)
	{ string }
}

export type privateConfig = {
	forcesList: { [string]: Vector3 },
	positionsList: { [string]: Vector3 },
	unitsConfig: { [string]: config },
	recoveryList: { [string]: number },
}

export type config = {
	speed: number,

	avoidRadius: number,
	alignRadius: number,
	centerRadius: number,

	avoidIntensity: number,
	alignIntensity: number,
	cohesionIntensity: number,

	goalIntensity: number,

	enableObstacleAvoidance: boolean,
	avoidObstaclesIntensity: number,
	recoveryTime: number,
	obstacleRayLength: number,
}

return {}
