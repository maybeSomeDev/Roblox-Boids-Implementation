[config]: configs.md#boids-configs

## FlockManager {: .class}

### .new {: .method }
```lua
local FlockManager = require(FlockManager)
FlockManager.new()
```
<div class="info">
Creates a new group manager container.
Used to share its data between all Boids in the group, and keep track of the Boids in the group.
</div>
!!! method-child ""
    Properties
    !!! prop ""
        config : [config][config]{: .data}
        ___
        group : <spin class="normal-data">{ string }</spin>
    Parameters
    !!! params ""
        config : [config][config]{: .data }

        Shared group config
    Returns
    !!! return ""
        manager : <spin class="normal-data">manager</spin>

---
<!--////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-->
### .getObjectByName {: .method }
```lua
FlockManager.getObjectByName(boidPart.Name)
```
!!! method-child ""
    Parameters
    !!! params ""
        name : <spin class="normal-data">string</spin>
    Returns
    !!! return ""
        boid : <spin class="normal-data">boid</spin>
---
<!--////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-->
### .getObjectConfig {: .method }

```lua
local config = FlockManager.getObjectConfig() -- Can be used to change one key
config.speed = 50
```

!!! method-child ""
    Parameters
    !!! params ""
        name : <spin class="normal-data">string | Instance</spin>
    Returns
    !!! return ""
        config : [config][config]{: .data }
---
<!--////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-->
### .setObjectConfig {: .method }
```lua
FlockManager.setObjectConfig(config : config)
```
<div class="info">
Sets or overwrites the Boid config.
</div>

!!! method-child ""
    Parameters
    !!! params ""
        name : <spin class="normal-data">string | Instance</spin>
        ___
        newConfig : [config][config]{: .data }
    Returns
    !!! return ""
        manager : <spin class="normal-data">manager</spin>

<!--
--[[================================================================]]
--[[////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\]]
--[[================================================================]]
 -->

---
## manager

<!--////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-->
### add {: .method }
```lua
manager:add(boids : { boids })
```
<div class="info">
Adds a new Boid to the group.
</div>
!!! method-child ""
    Parameters
    !!! params ""
        boids : <spin class="normal-data">boid</spin>
        ___
        config : [config][config]{: .data }

!!! warning
    Each Boid must have a unique name before being added to the group.

---
<!--////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-->
### start {: .method }
```lua
manager:start()
```
<div class="info">
Start applying the rules for the group.
</div>

---
<!--////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-->
### pause {: .method }
```lua
manager:pause()
```
<div class="info">
Pauses the excuteion of rules, you can call <mark>start()</mark> later.
</div>

---
<!--////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-->
### addStaticGoal {: .method }
```lua
manager:addStaticGoal(goalPart.Position)
```
!!! method-child ""
    Parameters
    !!! params ""
        goal : <spin class="normal-data">Vector3</spin>
        ___
        name? : <spin class="normal-data">string</spin>

        (Optional) Provide a name to link a goal to a Boid, or leave it empty to add a shared goal for all Boids in the group (manager).
---
<!--////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-->
### addDynamicGoal {: .method }
```lua
manager:addDynamicGoal(function()
    return goal.Position
end)
```

!!! method-child ""
    Parameters
    !!! params ""
        getGoal : <spin class="normal-data">function -> Vector3</spin>
        ___
        name? : <spin class="normal-data">string</spin>

        (Optional)

---
<!--////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-->
### removeGoal {: .method }
```lua
manager:removeGoal()
```
!!! method-child ""
    Parameters
    !!! params ""
        name? : <spin class="normal-data">string</spin>

        (Optional)
---
<!--////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-->
### remove {: .method }
```lua
manager:remove(boidPart.Name)
```
<div class="info">
Removes a boid from the group, and from the <mark>NetworkReplicator</mark> if Enabled.
</div>
!!! method-child ""
    Parameters
    !!! params ""
        name : <spin class="normal-data">string</spin>
        ___
        destroy?: <spin class="normal-data">boolean</spin>

        Destroy the Boid after removing it

        (Optional)
---
<!--////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-->
### clean {: .method }
```lua
manager:clean()
```
<div class="info">
Will call <mark>remove()</mark> for every Boid in this group, and will <mark>pause()</mark> executing the rules.
</div>

!!! method-child ""
    Parameters
    !!! params ""
        destroy?: <spin class="normal-data">boolean</spin>

        Destroy the Boid after removing it

        (Optional)
<!--////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-->