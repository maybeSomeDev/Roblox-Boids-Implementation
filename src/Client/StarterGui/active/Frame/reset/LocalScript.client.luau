local player = game.Players.LocalPlayer
local deactivateFreecam = game.ReplicatedStorage.DeactivateFreeCam

script.Parent.Activated:Connect(function()
	deactivateFreecam:Fire()
	workspace.CurrentCamera.CameraSubject = player.Character
end)