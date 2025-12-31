export type boid = Part & {
	["LinearVelocity"]: LinearVelocity, -- child
}

export type manager = {
	group: group,
	config: config,
	_goal: Vector3?,
}

export type group = {
	{ string }
}

export type privateConfig = {
	forcesList: { [string]: Vector3 },
	positionsList: { [string]: Vector3 },
	boidsConfig: { [string]: config },
	recoveryList: { [string]: number },
}

export type config = {
	speed: number,

	avoidRadius: number,
	alignRadius: number,
	cohesionRadius: number,

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
