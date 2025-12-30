[boid]: https://github.com/maybeSomeDev/Roblox-Boids-Implementation/blob/main/src/init.lua
[config]: https://github.com/maybeSomeDev/Roblox-Boids-Implementation/blob/main/src/init.lua
[manager]: https://github.com/maybeSomeDev/Roblox-Boids-Implementation/blob/main/src/init.lua

## FlockManager {: .class}

### .new {: .method }

<div class="info">
Create a new group manager
</div>
!!! method-child ""
    Parameters
    !!! func ""
        config : [config][config]{: .data }

        Shared Group config
    Returns
    !!! func ""
        manager : [manager][manager]{: .data }
        ___

### .getObjectByName {: .method }

!!! method-child ""
    Parameters
    !!! func ""
        name : <spin class="normal-data">string</spin>
    Returns
    !!! func ""
        boid : [boid][boid]{: .data }

### .getObjectConfig {: .method }

```lua
    -- Can be used to change one key of the config
    local config = FlockManager.getObjectConfig()
    config.speed = 50
``
!!! method-child ""
    Parameters
    !!! func ""
        name : <spin class="normal-data">string | Instance</spin>
    Returns
    !!! func ""
        config : [config][config]{: .data }

### .setObjectConfig {: .method }
<div class="info">
Set or overwrite the Boid config.
</div>
!!! method-child ""
    Parameters
    !!! func ""
        name : <spin class="normal-data">string | Instance</spin>
        ___
        newConfig : [config][config]{: .data }
    Returns
    !!! func ""
        manager : [manager][manager]{: .data }
        ___

## [manager][manager]{: .data }

### add {: .method }

<div class="info">
Add a new boid to a group.
</div>
!!! method-child ""
    Parameters
    !!! func ""
        objects : [{boid} | boid][boid]{: .data }
        ___
        config : [config][config]{: .data }

### start {: .method }

<div class="info">
Start applying the rules for the group.
</div>

### addStaticGoal {: .method }

<div class="info">
Info
</div>
!!! method-child ""
    Parameters
    !!! func ""
        goal : <spin class="normal-data">Vector3</spin>
        ___
        name? : <spin class="normal-data">string</spin>
        ___
        (Optional) Provide a name to link a goal to a Boid, or leave it empty to add a shared goal for all Boids in the group (manager)

!!! info
    Boids

### addDynamicGoal {: .method }
```lua
manager:addDynamicGoal(function()
    return goal.Position
end, name)
```
<div class="info">
Info
</div>
!!! method-child ""
    Parameters
    !!! func ""
        getGoal : <spin class="normal-data">function -> Vector3</spin>
        ___
        name : <spin class="normal-data">string</spin>

        (Optional)

### removeGoal {: .method }

<div class="info">
Info
</div>
!!! method-child ""
    Parameters
    !!! func ""
        name? : <spin class="normal-data">string</spin>

        (Optional)

### pause {: .method }

<div class="info">
Info
</div>

### remove {: .method }

<div class="info">
Info
</div>
!!! method-child ""
    Parameters
    !!! func ""
        name : <spin class="normal-data">string</spin>
        ___
        destroy?: <spin class="normal-data">boolean</spin>

        Destroy the Boid after removing it

        (Optional)

### clean {: .method }

<div class="info">
Info
</div>
!!! method-child ""
    Parameters
    !!! func ""
        destroy?: <spin class="normal-data">boolean</spin>

        Destroy the Boid after removing it

        (Optional)

## Utils Methods