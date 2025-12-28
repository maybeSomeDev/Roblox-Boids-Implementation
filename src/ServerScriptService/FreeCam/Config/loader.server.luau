-- Author: @Jumpathy
-- Name: loader.lua
-- Description: Load in freecam+
-- Get the source code here: https://www.roblox.com/library/9148889540/Freecam-Module

local runTesting = false
local moduleToRequire = 9148889540
local serverStorage = game:GetService("ServerStorage")
local config = require(script.Parent)

require(script.Parent.MainModule)(config)