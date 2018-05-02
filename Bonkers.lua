--[[
	This is a framework showing how to create a plugin for ElvUI.
	It creates some default options and inserts a GUI table to the ElvUI Config.
	If you have questions then ask in the Tukui lua section: https://www.tukui.org/forum/viewforum.php?f=10
]]

local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local EP = LibStub("LibElvUIPlugin-1.0") --We can use this to automatically insert our GUI tables when ElvUI_Config is loaded.
local addonName, addonTable = ... --See http://www.wowinterface.com/forums/showthread.php?t=51502&p=304704&postcount=2
local _G = _G
local BONK = E:NewModule(addonName, 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0'); --Create a plugin within ElvUI and adopt AceHook-3.0, AceEvent-3.0 and AceTimer-3.0. We can make use of these later.
BONK.callbacks = BONK.callbacks or LibStub("CallbackHandler-1.0"):New(BONK)

--Default options
P["BONK"] = {
	["TrinketPosition"] = "LEFT",
	["CDPosition"] = "LEFT",
    ["DRPosition"] = "RIGHT",
    ["CDFontSize"] = 20,
    ["DRFontSize"] = 20,
}

addonTable[1] = BONK
addonTable[2] = E
addonTable[3] = L
addonTable[4] = V
addonTable[5] = P
addonTable[6] = G
_G[addonName] = addonTable;

--Function we can call when a setting changes.
--In this case it just checks if "SomeToggleOption" is enabled. If it is it prints the value of "SomeRangeOption", otherwise it tells you that "SomeToggleOption" is disabled.
function BONK:Update()
	BONK:Update_PositionSettings()
    BONK:Update_IconSettings()
end

--This function inserts our GUI table into the ElvUI Config. You can read about AceConfig here: http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
function BONK:InsertOptions()
	E.Options.args.BONK = {
		order = 1,
		type = "group",
		name = "|cff9482c9Bonkers|r",
		args = {
			TrinketPosition = {
				order = 1,
				type = "select",
				name = "Trinket Position",
                values = {
                    ["RIGHT"] = "RIGHT",
                    ["LEFT"] = "LEFT",
                },
				get = function(info)
					return E.db.BONK.TrinketPosition
				end,
				set = function(info, value)
					E.db.BONK.TrinketPosition = value
					BONK:Update()
				end,
			},
            CDPosition = {
				order = 2,
				type = "select",
				name = "Cooldown Position",
                values = {
                    ["RIGHT"] = "RIGHT",
                    ["LEFT"] = "LEFT",
                },
				get = function(info)
					return E.db.BONK.CDPosition
				end,
				set = function(info, value)
					E.db.BONK.CDPosition = value
					BONK:Update()
				end,
			},
            DRPosition = {
				order = 3,
				type = "select",
				name = "DR Position",
                values = {
                    ["RIGHT"] = "RIGHT",
                    ["LEFT"] = "LEFT",
                },
				get = function(info)
					return E.db.BONK.DRPosition
				end,
				set = function(info, value)
					E.db.BONK.DRPosition = value
					BONK:Update()
				end,
			},
            CDFontSize = {
				order = 4,
				type = "range",
				name = "Timer Font Size",
                min = 1, max = 40, step = 1,
                get = function(info)
					return E.db.BONK.CDFontSize
				end,
				set = function(info, value)
					E.db.BONK.CDFontSize = value
					BONK:Update()
				end,
			},
            DRFontSize = {
				order = 5,
				type = "range",
				name = "DR Font Size",
                min = 1, max = 40, step = 1,
                get = function(info)
					return E.db.BONK.DRFontSize
				end,
				set = function(info, value)
					E.db.BONK.DRFontSize = value
					BONK:Update()
				end,
			},
		},
	}
end

function BONK:Initialize()
    self.initialized = true
	--Register plugin so options are properly inserted when config is loaded

	EP:RegisterPlugin(addonName, BONK.InsertOptions)
    BONK:InitOmni()
    BONK:Initialize_UnitFrames()
    print(E.db.BONK.TrinketPosition)
end

E:RegisterModule(addonName) --Register the module with ElvUI. ElvUI will now call BONK:Initialize() when ElvUI is ready to load our plugin.