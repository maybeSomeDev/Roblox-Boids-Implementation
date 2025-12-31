
## Install

Grab the module from the [repo](https://github.com/maybeSomeDev/Roblox-Boids-Implementation) or the latest
[.rbxmx](https://github.com/maybeSomeDev/Roblox-Boids-Implementation/releases/latest/download/FlockManager.rbxmx) version.

## Setup Your Boids

Spawn your Boid part and ensure that it has a `LinearVelocity` instance named 'LinearVelocity`.

!!! warning
    Each Boid must have a unique name.

!!! tip
    You can grab simple the spawner used in the test place from the repo, or by editing the uncopylocked place.

## The Scripts

```lua
-- Require the FlockManager once from the server
local flockModule = game.ReplicatedStorage.FlockManager
local flockManager = require(flockModule)
local config = require(flockModule.Config)

-- Create a new group ( the group will share the config file used passed here)
local manager = flockManager.new(config.testFile)

local birds = workspace.Birds:GetChildren()

-- Add your Boids
manager:add(birds)

-- And start applying the rules
manager:start()
```

!!! info
    Don't forget to change the <mark>config.global</mark> if you want to use the module on the client.

## Network Replicator

Enabling the network replicator doesn't require extra steps, just flipping it in the configs.
The Receiver script <mark>flockManager.NetworkReplicator.Receiver</mark>will handle the replication automatically.