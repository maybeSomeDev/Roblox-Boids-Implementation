------------------------------------------------------------------------
-- Freecam
-- Cinematic free camera for spectating and video production.
------------------------------------------------------------------------

local folder = game:GetService("ReplicatedStorage"):WaitForChild("FreecamPlus",100)
local config = folder:WaitForChild("config"):InvokeServer()
local modules = folder:WaitForChild("modules");

local pi    = math.pi
local abs   = math.abs
local clamp = math.clamp
local exp   = math.exp
local rad   = math.rad
local sign  = math.sign
local sqrt  = math.sqrt
local tan   = math.tan

local exceptions = {
	[script.Parent] = true
}

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local newCamera = Workspace.CurrentCamera
	if newCamera then
		Camera = newCamera
	end
end)

------------------------------------------------------------------------

local TOGGLE_INPUT_PRIORITY = Enum.ContextActionPriority.Low.Value
local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
local FREECAM_MACRO_KB = config.Macro

local NAV_GAIN = Vector3.new(1, 1, 1)*64
local PAN_GAIN = Vector2.new(0.75, 1)*8
local FOV_GAIN = 300

local PITCH_LIMIT = rad(90)

local VEL_STIFFNESS = 1.5
local PAN_STIFFNESS = (UserInputService.TouchEnabled and 4 or 1)
local FOV_STIFFNESS = (UserInputService.TouchEnabled and 2 or 4.0)

------------------------------------------------------------------------

local Spring = {} do
	Spring.__index = Spring

	function Spring.new(freq, pos)
		local self = setmetatable({}, Spring)
		self.f = freq
		self.p = pos
		self.v = pos*0
		return self
	end

	function Spring:Update(dt, goal)
		local f = self.f*2*pi
		local p0 = self.p
		local v0 = self.v

		local offset = goal - p0
		local decay = exp(-f*dt)

		local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
		local v1 = (f*dt*(offset*f - v0) + v0)*decay

		self.p = p1
		self.v = v1

		return p1
	end

	function Spring:Reset(pos)
		self.p = pos
		self.v = pos*0
	end
end

------------------------------------------------------------------------

local cameraPos = Vector3.new()
local cameraRot = Vector2.new()
local cameraFov = 0

local velSpring = Spring.new(VEL_STIFFNESS, Vector3.new())
local panSpring = Spring.new(PAN_STIFFNESS, Vector2.new())
local fovSpring = Spring.new(FOV_STIFFNESS, 0)

------------------------------------------------------------------------

local Input = {} do
	local thumbstickCurve do
		local K_CURVATURE = 2.0
		local K_DEADZONE = 0.15

		local function fCurve(x)
			return (exp(K_CURVATURE*x) - 1)/(exp(K_CURVATURE) - 1)
		end

		local function fDeadzone(x)
			return fCurve((x - K_DEADZONE)/(1 - K_DEADZONE))
		end

		function thumbstickCurve(x)
			return sign(x)*clamp(fDeadzone(abs(x)), 0, 1)
		end
	end

	local gamepad = {
		ButtonX = 0,
		ButtonY = 0,
		DPadDown = 0,
		DPadUp = 0,
		ButtonL2 = 0,
		ButtonR2 = 0,
		Thumbstick1 = Vector2.new(),
		Thumbstick2 = Vector2.new(),
	}

	local keyboard = {
		W = 0,
		A = 0,
		S = 0,
		D = 0,
		E = 0,
		Q = 0,
		U = 0,
		H = 0,
		J = 0,
		K = 0,
		I = 0,
		Y = 0,
		Up = 0,
		Down = 0,
		LeftShift = 0,
		RightShift = 0,
	}

	local mouse = {
		Delta = Vector2.new(),
		MouseWheel = 0,
	}

	local NAV_GAMEPAD_SPEED  = Vector3.new(1, 1, 1)
	local NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
	local PAN_MOUSE_SPEED    = Vector2.new(1, 1)*(pi/64)
	local PAN_GAMEPAD_SPEED  = Vector2.new(1, 1)*(pi/8)
	local FOV_WHEEL_SPEED    = config.Advanced.FovWheelSpeed
	local FOV_GAMEPAD_SPEED  = config.Advanced.FovGamepadSpeed
	local NAV_ADJ_SPEED      = config.Advanced.UpDownSpeed
	local NAV_SHIFT_MUL      = config.Advanced.ShiftSpeed
	local MOBILE_MUL = config.Advanced.MobileSpeed
	
	local navSpeed = 1
	local heldControllerShift = false
	
	-- since :IsKeyDown() wont work with this specific keybind >:(
	
	UserInputService.InputBegan:Connect(function(input)
		if(input.KeyCode == Enum.KeyCode.ButtonR1) then
			heldControllerShift = true
			local connection;
			connection = input.Changed:Connect(function()
				if(input.UserInputState == Enum.UserInputState.End) then
					connection:Disconnect()
					heldControllerShift = false
				end
			end)
		end
	end)

	function Input.Vel(dt)
		navSpeed = clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)

		local kGamepad = Vector3.new(
			thumbstickCurve(gamepad.Thumbstick1.X),
			thumbstickCurve(gamepad.ButtonR2) - thumbstickCurve(gamepad.ButtonL2),
			thumbstickCurve(-gamepad.Thumbstick1.Y)
		)*NAV_GAMEPAD_SPEED

		local kKeyboard = Vector3.new(
			keyboard.D - keyboard.A + keyboard.K - keyboard.H,
			keyboard.E - keyboard.Q + keyboard.I - keyboard.Y,
			keyboard.S - keyboard.W + keyboard.J - keyboard.U
		)*NAV_KEYBOARD_SPEED

		local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) or heldControllerShift
		
		return (kGamepad + kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or (UserInputService.TouchEnabled and MOBILE_MUL or 1)))
	end

	function Input.Pan(dt)
		local kGamepad = Vector2.new(
			thumbstickCurve(gamepad.Thumbstick2.Y),
			thumbstickCurve(-gamepad.Thumbstick2.X)
		)*PAN_GAMEPAD_SPEED
		local kMouse = mouse.Delta*PAN_MOUSE_SPEED
		mouse.Delta = Vector2.new()
		return kGamepad + kMouse
	end

	function Input.Fov(dt)
		local kGamepad = (gamepad.ButtonX - gamepad.ButtonY)*FOV_GAMEPAD_SPEED
		local kMouse = mouse.MouseWheel*FOV_WHEEL_SPEED
		mouse.MouseWheel = 0
		return kGamepad + kMouse
	end

	do
		local function Keypress(action, state, input)
			local new = state == Enum.UserInputState.Begin and 1 or 0
			local key = input.KeyCode.Name
			keyboard[key] = new

			return Enum.ContextActionResult.Sink
		end

		local function GpButton(action, state, input)
			gamepad[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
			return Enum.ContextActionResult.Sink
		end

		local function MousePan(action, state, input)
			local delta = input.Delta
			mouse.Delta = Vector2.new(-delta.y, -delta.x)
			return Enum.ContextActionResult.Sink
		end

		local function Thumb(action, state, input)
			gamepad[input.KeyCode.Name] = input.Position
			return Enum.ContextActionResult.Sink
		end

		local function Trigger(action, state, input)
			gamepad[input.KeyCode.Name] = input.Position.z
			return Enum.ContextActionResult.Sink
		end

		globalMouse = mouse;
		globalKp = Keypress

		local function MouseWheel(action, state, input)
			mouse[input.UserInputType.Name] = -input.Position.z
			return Enum.ContextActionResult.Sink
		end

		local function Zero(t)
			for k, v in pairs(t) do
				t[k] = v*0
			end
		end

		function Input.StartCapture()
			ContextActionService:BindActionAtPriority("FreecamKeyboard", Keypress, false, INPUT_PRIORITY,
				Enum.KeyCode.W, Enum.KeyCode.U,
				Enum.KeyCode.A, Enum.KeyCode.H,
				Enum.KeyCode.S, Enum.KeyCode.J,
				Enum.KeyCode.D, Enum.KeyCode.K,
				Enum.KeyCode.E, Enum.KeyCode.I,
				Enum.KeyCode.Q, Enum.KeyCode.Y,
				Enum.KeyCode.Up, Enum.KeyCode.Down
			)
			ContextActionService:BindActionAtPriority("FreecamMousePan",          MousePan,   false, INPUT_PRIORITY, Enum.UserInputType.MouseMovement)
			ContextActionService:BindActionAtPriority("FreecamMouseWheel",        MouseWheel, false, INPUT_PRIORITY, Enum.UserInputType.MouseWheel)
			ContextActionService:BindActionAtPriority("FreecamGamepadButton",     GpButton,   false, INPUT_PRIORITY, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)
			ContextActionService:BindActionAtPriority("FreecamGamepadTrigger",    Trigger,    false, INPUT_PRIORITY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
			ContextActionService:BindActionAtPriority("FreecamGamepadThumbstick", Thumb,      false, INPUT_PRIORITY, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
		end

		function Input.StopCapture()
			navSpeed = 1
			Zero(gamepad)
			Zero(keyboard)
			Zero(mouse)
			ContextActionService:UnbindAction("FreecamKeyboard")
			ContextActionService:UnbindAction("FreecamMousePan")
			ContextActionService:UnbindAction("FreecamMouseWheel")
			ContextActionService:UnbindAction("FreecamGamepadButton")
			ContextActionService:UnbindAction("FreecamGamepadTrigger")
			ContextActionService:UnbindAction("FreecamGamepadThumbstick")
		end
	end
end

local function GetFocusDistance(cameraFrame)
	local znear = 0.1
	local viewport = Camera.ViewportSize
	local projy = 2*tan(cameraFov/2)
	local projx = viewport.x/viewport.y*projy
	local fx = cameraFrame.rightVector
	local fy = cameraFrame.upVector
	local fz = cameraFrame.lookVector

	local minVect = Vector3.new()
	local minDist = 512

	for x = 0, 1, 0.5 do
		for y = 0, 1, 0.5 do
			local cx = (x - 0.5)*projx
			local cy = (y - 0.5)*projy
			local offset = fx*cx - fy*cy + fz
			local origin = cameraFrame.p + offset*znear
			local _, hit = Workspace:FindPartOnRay(Ray.new(origin, offset.unit*minDist))
			local dist = (hit - origin).magnitude
			if minDist > dist then
				minDist = dist
				minVect = offset.unit
			end
		end
	end

	return fz:Dot(minVect)*minDist
end

------------------------------------------------------------------------

local function StepFreecam(dt)
	local vel = velSpring:Update(dt, Input.Vel(dt))
	local pan = panSpring:Update(dt, Input.Pan(dt))
	local fov = fovSpring:Update(dt, Input.Fov(dt))

	local zoomFactor = sqrt(tan(rad(70/2))/tan(rad(cameraFov/2)))

	cameraFov = clamp(cameraFov + fov*FOV_GAIN*(dt/zoomFactor), 1, 120)
	cameraRot = cameraRot + pan*PAN_GAIN*(dt/zoomFactor)
	cameraRot = Vector2.new(clamp(cameraRot.x, -PITCH_LIMIT, PITCH_LIMIT), cameraRot.y%(2*pi))

	local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*NAV_GAIN*dt)
	cameraPos = cameraCFrame.p

	Camera.CFrame = cameraCFrame
	Camera.Focus = cameraCFrame*CFrame.new(0, 0, -GetFocusDistance(cameraCFrame))
	Camera.FieldOfView = cameraFov
end

------------------------------------------------------------------------

local cameraType

local PlayerState = {} do
	local mouseBehavior
	local mouseIconEnabled
	local cameraFocus
	local cameraCFrame
	local cameraFieldOfView
	local screenGuis = {}
	local coreGuis = {

	}
	
	for _,enum in pairs(Enum.CoreGuiType:GetEnumItems()) do
		if(enum.Name ~= "All") then
			coreGuis[enum.Name] = true
		end
	end
	
	local setCores = {
		BadgesNotificationsActive = true,
		PointsNotificationsActive = true,
	}

	-- Save state and set up for freecam
	function PlayerState.Push()
		for name in pairs(coreGuis) do
			coreGuis[name] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType[name])
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], false)
		end
		for name in pairs(setCores) do
			setCores[name] = StarterGui:GetCore(name)
			StarterGui:SetCore(name, false)
		end
		local playergui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if playergui then
			for _, gui in pairs(playergui:GetChildren()) do
				if gui:IsA("ScreenGui") and gui.Enabled and (not exceptions[gui]) then
					--/changed
					if gui.Name == "active" then continue end
					screenGuis[#screenGuis + 1] = gui
					gui.Enabled = false
				end
			end
		end

		cameraFieldOfView = Camera.FieldOfView
		Camera.FieldOfView = 70

		cameraType = Camera.CameraType
		Camera.CameraType = Enum.CameraType.Custom

		cameraCFrame = Camera.CFrame
		cameraFocus = Camera.Focus

		mouseIconEnabled = UserInputService.MouseIconEnabled
		--/changed
		--UserInputService.MouseIconEnabled = false

		mouseBehavior = UserInputService.MouseBehavior
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	-- Restore state
	function PlayerState.Pop()
		for name, isEnabled in pairs(coreGuis) do
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], isEnabled)
		end
		for name, isEnabled in pairs(setCores) do
			StarterGui:SetCore(name, isEnabled)
		end
		for _, gui in pairs(screenGuis) do
			if gui.Parent then
				gui.Enabled = true
			end
		end

		Camera.FieldOfView = cameraFieldOfView
		cameraFieldOfView = nil

		Camera.CameraType = cameraType
		cameraType = nil

		Camera.CFrame = cameraCFrame
		cameraCFrame = nil

		Camera.Focus = cameraFocus
		cameraFocus = nil

		UserInputService.MouseIconEnabled = mouseIconEnabled
		--/changed
		--mouseIconEnabled = nil

		UserInputService.MouseBehavior = mouseBehavior
		mouseBehavior = nil
	end
end

local on = function(state)
	if config.BecomeInvisible then
		local remote = script.Parent:WaitForChild("SetInvisibility")
		remote:FireServer(state)
	end
end

local function StartFreecam()
	on(true)
	local cameraCFrame = Camera.CFrame
	cameraRot = Vector2.new(cameraCFrame:toEulerAnglesYXZ())
	cameraPos = cameraCFrame.p
	cameraFov = Camera.FieldOfView

	velSpring:Reset(Vector3.new())
	panSpring:Reset(Vector2.new())
	fovSpring:Reset(0)

	PlayerState.Push()
	RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
	Input.StartCapture()
end

local function StopFreecam()
	on(false)
	Input.StopCapture()
	RunService:UnbindFromRenderStep("Freecam")
	PlayerState.Pop()
end

------------------------------------------------------------------------

do
	local enabled = false
	local handle;

	local function ToggleFreecam()
		if enabled then
			StopFreecam()
		else
			StartFreecam()
		end
		enabled = not enabled
		handle(enabled)
	end

	local function CheckMacro(macro)
		for i = 1, #macro - 1 do
			if not UserInputService:IsKeyDown(macro[i]) then
				return
			end
		end
		ToggleFreecam()
	end
	--/changed
	local toggleEvent = game:GetService("ReplicatedStorage").ToggleFreeCam
	local deactivate = game:GetService("ReplicatedStorage").DeactivateFreeCam
	toggleEvent.Event:Connect(ToggleFreecam)
	deactivate.Event:Connect(function()
		if enabled then
			enabled = false
			StopFreecam()
			handle(enabled)
		end
	end)
	
	local function HandleActivationInput(action, state, input)
		if state == Enum.UserInputState.Begin then
			if input.KeyCode == FREECAM_MACRO_KB[#FREECAM_MACRO_KB] then
				CheckMacro(FREECAM_MACRO_KB)
			end
		end
		return Enum.ContextActionResult.Pass
	end

	ContextActionService:BindActionAtPriority("FreecamToggle", HandleActivationInput, false, INPUT_PRIORITY + 1, FREECAM_MACRO_KB[#FREECAM_MACRO_KB])

	local replicatedStorage = game:GetService("ReplicatedStorage")
	local uis = game:GetService("UserInputService")
	local localPlayer = game:GetService("Players").LocalPlayer;

	local topbarPlusReference = replicatedStorage:FindFirstChild("TopbarPlusReference")
	local iconModule = modules:WaitForChild("icon")
	if topbarPlusReference then
		iconModule = topbarPlusReference.Value
	end

	local Icon = require(iconModule)
	
	--------------------------
	
	local tsGui;
	local mobileMovementControlInit = function()
		local lastTouchScale = nil
		local cameraZoom = 15;
		local cameraZoomBounds = nil --{10,200}
		local last = 0
		local zoomScale = config.Advanced.FovWheelSpeed * 3/4;
		local thumbstickMoving;
		local lastChange = tick() - 0.1
		
		local thumbstick = require(modules.thumbstick)
		tsGui = thumbstick:Create(script.Parent,config.ThumbstickVisibleForMobile,function(keycode,pressed)
			globalKp(nil,(pressed and Enum.UserInputState.Begin or Enum.UserInputState.End),{KeyCode = keycode})
		end,function()
			local keys = {Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D}
			for _,key in pairs(keys) do
				globalKp(nil,Enum.UserInputState.End,{KeyCode = key});
			end
		end,function(moving)
			thumbstickMoving = moving
			lastChange = tick()
		end)

		uis.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
			if state == Enum.UserInputState.Change or state == Enum.UserInputState.End then
				if(enabled and (not thumbstickMoving) and (tick() - lastChange) > 0.1) then
					local difference = scale - lastTouchScale
					cameraZoom = cameraZoom * (1 + difference)
					if cameraZoomBounds ~= nil then
						cameraZoom = math.min(math.max(cameraZoom, cameraZoomBounds[1]), cameraZoomBounds[2])
					else
						cameraZoom = math.max(cameraZoom, 0)
					end
					localPlayer.CameraMinZoomDistance = 5;
					localPlayer.CameraMaxZoomDistance = 5;
					local diff = (((cameraZoom - last) < 1) and (zoomScale) or (-zoomScale))
					globalMouse["MouseWheel"] = diff
					last = cameraZoom
				end
			end
			lastTouchScale = scale
		end)

		local lastTouchTranslation = nil
		uis.TouchPan:Connect(function(touchPositions, totalTranslation, velocity, state)
			if state == Enum.UserInputState.Change or state == Enum.UserInputState.End then
				if(enabled and (not thumbstickMoving)) then
					local difference = totalTranslation - lastTouchTranslation;
					globalMouse.Delta = Vector2.new(-difference.Y, -difference.X);
				end
			end
			lastTouchTranslation = totalTranslation
		end)
	end
	
	local iconSetup;
	local setupIcon = function()
		if(not iconSetup) then
			iconSetup = true;
		else
			return;
		end
		local pre,pre2 = 0,0;
		
		local icon = Icon.new():setImage(config.FreecamImage):setName("freeCamToggle")
		--/changed
		icon:setEnabled(false)
		exceptions[localPlayer.PlayerGui.TopbarStandard] = true
		
		handle = function(state)
			icon[state and "select" or "deselect"](icon)
		end

		local push = function(state)
			enabled = state
			if(not enabled and (cameraType ~= nil)) then
				StopFreecam()
			elseif(enabled and (not cameraType)) then
				StartFreecam()
			end
		end
		
		local reEnable = {}

		icon.selected:Connect(function()
			if(tsGui) then
				tsGui.Visible = true;
			end
			pre = localPlayer.CameraMinZoomDistance;
			pre2 = localPlayer.CameraMaxZoomDistance;
			push(true)
			for _,topbarIcon in pairs(Icon.getIcons()) do
				if(topbarIcon.enabled and (topbarIcon.name ~= "freeCamToggle")) then
					topbarIcon:setEnabled(false)
					reEnable[topbarIcon] = true
				end
			end
		end)

		icon.deselected:Connect(function()
			push(false)
			for topbarIcon,_ in pairs(reEnable) do
				topbarIcon:setEnabled(true)
			end
			localPlayer.CameraMinZoomDistance = pre
			localPlayer.CameraMaxZoomDistance = pre2
			if(tsGui) then
				tsGui.Visible = false
			end
		end)
	end
		
	if(uis.TouchEnabled) then
		setupIcon()
		mobileMovementControlInit()
	else
		handle = function() end
	end
	
	local guiService = game:GetService("GuiService");
	if(guiService:IsTenFootInterface()) then
		setupIcon()
	else
		local connectedSignal;
		connectedSignal = UserInputService.GamepadConnected:Connect(function()
			connectedSignal:Disconnect();
			setupIcon()
		end)
		for _,opt in pairs(UserInputService:GetConnectedGamepads()) do
			setupIcon()
		end
	end
end