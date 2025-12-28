local player = game.Players.LocalPlayer
local activate = game.ReplicatedStorage.ToggleFreeCam
script.Parent.Activated:Connect(function()
	activate:Fire()
end)