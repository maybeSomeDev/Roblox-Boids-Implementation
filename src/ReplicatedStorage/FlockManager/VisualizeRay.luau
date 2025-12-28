local m = {}

local activeVisualizers = {}
local hideTimers = {}
local HIDE_POSITION = Vector3.new(0, 1000, 0)

local function createPart(config)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = config.Material or Enum.Material.Neon
	part.Transparency = config.Transparency or 0.5
	part.Size = config.Size
	part.Shape = config.Shape or Enum.PartType.Block
	part.Parent = workspace
	part.Position = HIDE_POSITION
	return part
end

local function hideVisualizer(name: string)
	if activeVisualizers[name] then
		for _, part in activeVisualizers[name] do
			part.Position = HIDE_POSITION
		end
	end
	if hideTimers[name] then
		--task.cancel(hideTimers[name])
		hideTimers[name] = nil
	end
end

function m.visualizeRay(name: string, origin: Vector3, direction: Vector3, result: RaycastResult?, duration: number?)
	if not activeVisualizers[name] then
		activeVisualizers[name] = {
			rayPart = createPart({Size = Vector3.new(0.1, 0.1, 1)}),
			hitMarker = createPart({Size = Vector3.new(0.5, 0.5, 0.5), Shape = Enum.PartType.Ball})
		}
	end

	local parts = activeVisualizers[name]
	if not parts.rayPart then return end
	-- Update ray line
	parts.rayPart.Size = Vector3.new(0.1, 0.1, direction.Magnitude)
	parts.rayPart.CFrame = CFrame.lookAt(origin, origin + direction) * CFrame.new(0, 0, -direction.Magnitude / 2)
	parts.rayPart.Color = result and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)

	-- Update hit marker
	if result then
		parts.hitMarker.Position = result.Position
	else
		parts.hitMarker.Position = HIDE_POSITION
	end

	if hideTimers[name] then
		task.cancel(hideTimers[name])
	end

	if duration then
		hideTimers[name] = task.delay(duration, function()
			hideVisualizer(name)
		end)
	end
end

function m.visualizeRayOut(name: string, origin: Vector3, direction: Vector3, result: RaycastResult?, duration: number?,color)
	if not activeVisualizers[name] then
		activeVisualizers[name] = {
			rayPart = createPart({Size = Vector3.new(0.1, 0.1, 1)}),
			hitMarker = createPart({Size = Vector3.new(0.5, 0.5, 0.5), Shape = Enum.PartType.Ball})
		}
	end

	local parts = activeVisualizers[name]

	-- Update ray line
	parts.rayPart.Size = Vector3.new(0.1, 0.1, direction.Magnitude)
	parts.rayPart.CFrame = CFrame.lookAt(origin, origin + direction) * CFrame.new(0, 0, -direction.Magnitude / 2)
	parts.rayPart.Color = color

	-- Update hit marker
	parts.hitMarker.Position = origin:Lerp(origin + direction,0.5)
	--if result then
	--else
	--	parts.hitMarker.Position = HIDE_POSITION
	--end

	if hideTimers[name] then
		--task.cancel(hideTimers[name])
	end

	if duration then
		hideTimers[name] = task.delay(duration, function()
			hideVisualizer(name)
		end)
	end
end


function m.visualizeSphereCast(name: string, origin: Vector3, direction: Vector3, radius: number, result: RaycastResult?, duration: number?)
	if not activeVisualizers[name] then
		activeVisualizers[name] = {
			startSphere = createPart({Size = Vector3.new(1, 1, 1), Shape = Enum.PartType.Ball, Material = Enum.Material.ForceField, Transparency = 0.7}),
			endSphere = createPart({Size = Vector3.new(1, 1, 1), Shape = Enum.PartType.Ball, Material = Enum.Material.ForceField, Transparency = 0.7}),
			beam = createPart({Size = Vector3.new(0.1, 0.1, 1), Transparency = 0.6}),
			hitMarker = createPart({Size = Vector3.new(0.6, 0.6, 0.6), Shape = Enum.PartType.Ball})
		}
	end

	local parts = activeVisualizers[name]
	local endPos = result and result.Position or (origin + direction)
	if not parts.startSphere then return end
	-- Update start sphere
	parts.startSphere.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
	parts.startSphere.Position = origin
	parts.startSphere.Color = result and Color3.new(1, 0, 0) or Color3.new(0, 0.5, 1)

	-- Update end sphere
	parts.endSphere.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
	parts.endSphere.Position = endPos
	parts.endSphere.Color = result and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)

	-- Update beam
	parts.beam.Size = Vector3.new(0.1, 0.1, (endPos - origin).Magnitude)
	parts.beam.CFrame = CFrame.lookAt(origin, endPos) * CFrame.new(0, 0, -(endPos - origin).Magnitude / 2)
	parts.beam.Color = result and Color3.new(1, 0.5, 0) or Color3.new(0, 1, 1)

	-- Update hit marker
	if result then
		parts.hitMarker.Position = result.Position
	else
		parts.hitMarker.Position = HIDE_POSITION
	end

	if hideTimers[name] then
		task.cancel(hideTimers[name])
	end

	if duration then
		hideTimers[name] = task.delay(duration, function()
			hideVisualizer(name)
		end)
	end
end

local function clear(name: string)
	hideVisualizer(name)
end

local function clearAll()
	for name in activeVisualizers do
		hideVisualizer(name)
	end
end

return m