## Links

[Devforum Post](https://github.com/maybeSomeDev/Roblox-Boids-Implementation)

<a href="https://www.roblox.com/games/111714118557618" title="Uncopylocked">Test Place</a>

[Download .rbxmx](https://github.com/maybeSomeDev/Roblox-Boids-Implementation/releases/latest/download/FlockManager.rbxmx)

## Introduction

[Boids](https://en.wikipedia.org/wiki/Boids) is an algorithm developed by [Craig Reynolds](https://en.wikipedia.org/wiki/Craig_Reynolds_(computer_graphics)) with the aim of replicating the flocking behavior of birds, fish, and herding animals.

##### Use Cases
- Schools of fish, a flock of birds, or insect swarms
- Horde of zombies
- Drones
- Particles
- Unit formations

## Showcase

<iframe width="640" height="360" src="https://www.youtube.com/embed/SJ3V-Il7UO4" title="Roblox Boids Showcase" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

## Example Usage 
[More Eaxmples](about.md)
```lua
-- main
local flockModule = game.ReplicatedStorage.FlockManager
local flockManager = require(flockModule)
local config = require(flockModule.Config)

local manager = flockManager.new(config.testFile)

local birds = workspace.Birds:GetChildren() :: { Part } -- with a LinearVelocity child

manager:add(birds)

manager:start()
```

```lua
-- config
m.testFile = {
	speed = 25,

	avoidRadius = 6,
	alignRadius = 35,
	centerRadius = 45,

	avoidIntensity = 2,
	alignIntensity = 1.5,
	cohesionIntensity = 1.2,

	goalIntensity = 7,
	
	enableObstacleAvoidance = true,
	avoidObstaclesIntensity = 30,
	-- hitting an obstacle makes the bird ignore all rules other than Avoidance and ObstacleAvoidance
	-- to focus only on not hitting its head
	recoveryTime = 0.1, -- seconds
	-- Multiplier: speed * obstacleRayLength = real RayLength
	obstacleRayLength = 2,
}
```
## Features
- The core 3 rules (separation, alignment, cohesion)
- Obstacle avoidance
- Target following

#### Optimization Techniques Used
- Spatial Partitioning ([Grids](https://gameprogrammingpatterns.com/spatial-partition.html))
- Network Replicator (To reduce the bandwidth)
- Multithreading ([Parallel Luau](https://create.roblox.com/docs/scripting/multithreading))

#### 3rd Party Tools Used: 
- [Packet](https://devforum.roblox.com/t/packet-networking-library/3573907) (To handle batching and compression)

!!! info "Planned"
    - Moving from `LinearVelocity` to `CFrame` based movement
    - Better steering/ smoother turning
    - More optimizations 


!!! bug "Known Issues"
    - Objects with `CanCollide` disabled may pass through walls at low framerates.
        -  Cause: Object movement is dependent on `LinearVelocity` (Roblox physics), which can update an object's position at low framerates before the Obstacle Avoidance code can check for collisions

Note: Some use cases may require you to modify the system,or remove some of the features, or only use a small part of it.