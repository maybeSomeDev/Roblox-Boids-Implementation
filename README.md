## Links
  
- [Docs](https://maybesomedev.github.io/Roblox-Boids-Implementation/)

- [Devforum Post](https://github.com/maybeSomeDev/Roblox-Boids-Implementation)

- <a href="https://www.roblox.com/games/111714118557618" title="Uncopylocked">Test Place</a>

## Introduction

[Boids](https://en.wikipedia.org/wiki/Boids) is an algorithm developed by [Craig Reynolds](https://en.wikipedia.org/wiki/Craig_Reynolds_(computer_graphics)) with the aim of replicating the flocking behavior of birds, fish, and herding animals.

##### Use Cases
- Schools of fish, a flock of birds, or insect swarms
- Horde of zombies
- Drones
- Particles
- Unit formations

## Showcase
<a href="http://www.youtube.com/watch?feature=player_embedded&v=SJ3V-Il7UO4
" target="_blank"><img src="http://img.youtube.com/vi/SJ3V-Il7UO4/0.jpg" /></a>

## Example Usage 
<!-- [More Eaxmples](about.md) -->
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

## Features
- The core 3 rules (separation, alignment, cohesion)
- Obstacle avoidance
- Target following

#### Optimization Techniques Used
- Spatial Partitioning ([Grids](https://gameprogrammingpatterns.com/spatial-partition.html))
- Network Replicator (To reduce the bandwidth)
- Multithreading ([Parallel Luau](https://create.roblox.com/docs/scripting/multithreading))

Using [Packet](https://devforum.roblox.com/t/packet-networking-library/3573907) (To handle batching and compression)
