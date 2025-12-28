--[[
	  ______                                         
	 |  ____|                                    _   
	 | |__ _ __ ___  ___  ___ __ _ _ __ ___    _| |_ 
	 |  __| '__/ _ \/ _ \/ __/ _` | '_ ` _ \  |_   _|
	 | |  | | |  __/  __/ (_| (_| | | | | | |   |_|  
	 |_|  |_|  \___|\___|\___\__,_|_| |_| |_|        
	                                                 
	 - Roblox's built in freecam with more customizability and access to more platforms!  
--]]

return {
	Macro = {Enum.KeyCode.LeftShift,Enum.KeyCode.P}, --> Keybind to enter / exit freecam for keyboard
	FreecamImage = "rbxassetid://9145693009", --> For mobile/console support, the freecam topbar icon image
	ThumbstickVisibleForMobile = true, --> The thumbstick is used for movement on mobile, but can be made invisible with this option for more screen space.
	Advanced = {
		FovWheelSpeed = 1.0, --> Percentage of original speed when zooming in
		FovGamepadSpeed = 0.25, --> Percentage of original speed when zooming in on gamepad
		UpDownSpeed = 0.75, --> Percentage of original speed when moving up / down
		ShiftSpeed = 3.25, --> Percentage of original speed when holding shift down
		MobileSpeed = 0.5 --> Percentage of original speed when on mobile
	},
	Permissions = { --> Extended freecam permissions
		Groups = {
			[0] = 255 --> The owner of group [0] gets freecam automatically
		},
		Users = {1}, --> User 1 (Roblox) gets freecam
		Gamepasses = {28005026} --> Owning the gamepass 0 automatically gives the user freecam
	}
}