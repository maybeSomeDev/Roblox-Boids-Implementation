## Global Configs

| Name | Type<br>___<br>Range | Description |
|---|:---:|---|
| serverSide | bool | Whether the module will be used server or client side **only**<br>This is important for setting up the Actors to match the run context |
| updateFrequency | number<br>0-60 | Number of frames to skip<br>0 to update (apply the rules) every frame |
| gridCellSize | number<br>1-50 | The size of the cell<br>Nearby Boids will be detected by forming a 3x3 (9) cells around the Boid and getting the neighbors in them<br><br>Value x 3 = **Must be bigger or equal** to the Boid's biggest detection radius<br>For example: if the Boid's biggest raidus is cohessionRadius (45) gridCellSize must be at least 15 |
| generatedDirectionCount | number<br>5-200 | Number of sphere shaped directions<br>Used to detect obstacles by casting rays in all directions around the Boid<br><br>Recommended Value: 15-30 |
| numberOfWorkers | number<br>0-64 | Number of Actors to split the work among |
| flockCollisionGroup | string | The Boids collision group<br>Used to ignore each others when searching for obstacles to avoid<br><br>Adding a new Boid to the group will **overwrite its CollisionGroup** with this value." |

\frac{a}{b}

## Network Replicator Configs
.network

| Name | Type<br>___<br>Range| Description |
| :--- | :---: | :--- |
| enable  | bool  | Whether to enable or disable the Network Replicator |
| updateRate | seconds<br>0.1-0.5  | How often data is sent to the player |
| clientDelayMultiplier  | number/scaler<br>2-10 | How far in the past the client stays to ensure smooth movement <br><br> Recommended: 2.1-3.5 |

## Boids Configs
Can be move out of the conifg module.

| Name | Type | Description |
| :--- | :---: | :--- |
| Speed | number | Adjust the **constant** speed of the Boid |
| avoidRadius | number | Radius used to push Boids away from each other |
| avoidIntensity | number | The strength used to push the Boids, and **priority** of the push over other forces |
| alignRadius | number | Radius used to make nearby Boids head towards the same direction |
| alignIntensity | number | Strength & priority of the pull  |
| centerRadius | number | Radius used to pull nearby Boids to the center of the group |
| cohesionIntensity | number | 	Strength & priority of the pull |
| goalIntensity | number | 	Strength & priority of the pull toward the target |
| enableObstacleAvoidance | bool | Enable avoiding obstacles/walls in the Boid's path |
| avoidObstaclesIntensity | number | Strength & priority of the push |
| recoveryTime | seconds | The time it takes for a Boid to return to normal flocking behavior after dodging an obstacle |
| obstacleRayLength  | number | The size of the detection rays |