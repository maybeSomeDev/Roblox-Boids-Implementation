-- Author: @Jumpathy
-- Name: MainModule.lua
-- Description: Freecam+ server

return function(config)
	local players = game:GetService("Players")
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local marketplace = game:GetService("MarketplaceService")

	local freecamPlus = Instance.new("Folder")
	freecamPlus.Parent = replicatedStorage
	freecamPlus.Name = "FreecamPlus"

	script.modules.Parent = freecamPlus

	local freecamEvent = Instance.new("RemoteFunction")
	freecamEvent.Parent = freecamPlus
	freecamEvent.Name = "config"
	freecamEvent.OnServerInvoke = function()
		return config
	end

	local assigned,hasFreecam = {},{}
	local permissions = config.Permissions
	local gamepasses = permissions.Gamepasses

	local setInvisible = function(player,state)
		local character = player.Character

		for _,object in pairs(character:GetDescendants()) do
			pcall(function()
				local transparency = object.Transparency
				if not object:GetAttribute("DefaultTransparency") then
					object:SetAttribute("DefaultTransparency",transparency)
				end
				if(object.Name ~= "HumanoidRootPart") then
					object.Transparency = state and 1 or (object:GetAttribute("Transparency") or 0)
				end
			end)
		end
	end

	local giveFreecam = function(player)
		local obj = Instance.new("ScreenGui")
		obj.Name = "Freecam"
		obj.Parent = player.PlayerGui
	end

	local onPlayer = function(player)
		local playerGui = player.PlayerGui

		local objectAdded = function(object)
			if(object.Name == "Freecam" and (not assigned[object])) then
				object:Destroy()
				if(not hasFreecam[player]) then
					local toAssign = script:WaitForChild("dependencies"):WaitForChild("Freecam"):Clone()
					assigned[toAssign] = true
					hasFreecam[player] = true
					toAssign.Parent = playerGui
					
					if config.BecomeInvisible then
						local remote = Instance.new("RemoteEvent")
						remote.Parent = toAssign
						remote.Name = "SetInvisibility"
						remote.OnServerEvent:Connect(function(p,state)
							if(p == player) then
								setInvisible(p,state)
							end
						end)
					end
				end
			end
		end

		playerGui.ChildAdded:Connect(objectAdded)
		for _,object in pairs(playerGui:GetChildren()) do
			task.spawn(objectAdded,object)
		end

		task.spawn(function()
			for _,passId in pairs(gamepasses) do
				pcall(function()
					if(marketplace:UserOwnsGamePassAsync(player.UserId,passId)) then
						giveFreecam(player)
					end
				end)
			end
		end)

		task.spawn(function()
			for groupId,requiredRank in pairs(permissions.Groups) do
				if(player:GetRankInGroup(groupId) >= requiredRank) then
					giveFreecam(player)
				end
			end
		end)

		for _,user in pairs(permissions.Users) do
			if(player.UserId == user or (player.Name == user)) then
				giveFreecam(player)
			end
		end
	end

	players.PlayerAdded:Connect(onPlayer)
	for _,player in pairs(players:GetPlayers()) do
		task.spawn(onPlayer,player)
	end

	marketplace.PromptGamePassPurchaseFinished:Connect(function(player,id,wasPurchased)
		if(wasPurchased and table.find(gamepasses,id)) then
			giveFreecam(player)
		end
	end)
end