local player = game.Players.LocalPlayer
local deactivateFreecam = game.ReplicatedStorage.DeactivateFreeCam

script.Parent.Activated:Connect(function()
	local birds = workspace.Birds:GetChildren()
	local count = #birds
	local pick = birds[math.random(1,count)]

	deactivateFreecam:Fire()
	workspace.CurrentCamera.CameraType = Enum.CameraType.Track
	workspace.CurrentCamera.CameraSubject = pick
end)