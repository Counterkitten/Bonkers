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
    ["General"] = {
        ["Stack"] = false,
        ["SeparatorY"] = 3,
        ["Order"] = "spells",
        ["Debug"] = false
    },
    ["Trinket"] = {
        ["Enabled"] = true,
        ["Position"] = "LEFT",
        ["TimerFontSize"] = 15,
        ["SeparatorX"] = 0,
        ["IconSize"] = 1,
    },
    ["CD"] = {
        ["Enabled"] = true,
        ["Position"] = "LEFT",
        ["TimerFontSize"] = 15,
        ["SeparatorX"] = 10,
        ["PaddingX"] = 3,
        ["IconSize"] = 1,
    },
    ["DR"] = {
        ["Enabled"] = true,
        ["Position"] = "LEFT",
        ["TimerFontSize"] = 15,
        ["DRFontSize"] = 20,
        ["SeparatorX"] = 10,
        ["PaddingX"] = 3,
        ["IconSize"] = 1,
    },
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
	BONK.BFM:RefreshSettings()
end

--This function inserts our GUI table into the ElvUI Config. You can read about AceConfig here: http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
function BONK:InsertOptions()
	E.Options.args.BONK = {
		order = 1,
		type = "group",
		name = "|cff9482c9Bonkers|r",
        childGroups = "tab",
		args = {
            General = {
                order = 1,
                type = "group",
                name = "General",
                args = {
                    TrinketEnabled = {
                        order = 1,
                        type = "toggle",
                        name = "Enable Trinket",
                        get = function(info)
                            return E.db.BONK.Trinket.Enabled
                        end,
                        set = function(info, value)
                            E.db.BONK.Trinket.Enabled = value
                            BONK:Update()
                        end,
                    },
                    CDEnabled = {
                        order = 2,
                        type = "toggle",
                        name = "Enable Cooldowns",
                        get = function(info)
                            return E.db.BONK.CD.Enabled
                        end,
                        set = function(info, value)
                            E.db.BONK.CD.Enabled = value
                            BONK:Update()
                        end,
                    },
                    DREnabled = {
                        order = 3,
                        type = "toggle",
                        name = "Enable DRs",
                        get = function(info)
                            return E.db.BONK.DR.Enabled
                        end,
                        set = function(info, value)
                            E.db.BONK.DR.Enabled = value
                            BONK:Update()
                        end,
                    },
                    Stack = {
                        order = 4,
                        type = "toggle",
                        name = "Stack Icons",
                        desc = "Stack CD and DR icons",
                        get = function(info)
                            return E.db.BONK.General.Stack
                        end,
                        set = function(info, value)
                            E.db.BONK.General.Stack = value
                            BONK:Update()
                        end,
                        disabled = function()
                            return not (E.db.BONK.CD.Position == E.db.BONK.DR.Position)
                        end,
                    },
                    SeparatorY = {
                        order = 5,
                        type = "range",
                        name = "Stack Separator",
                        min = 0, max = 20, step = 1,
                        get = function(info)
                            return E.db.BONK.General.SeparatorY
                        end,
                        set = function(info, value)
                            E.db.BONK.General.SeparatorY = value
                            BONK:Update()
                        end,
                        disabled = function()
                            return E.db.BONK.General.Stack == false or not (E.db.BONK.CD.Position == E.db.BONK.DR.Position)
                        end,
                    },
                    Order = {
                        order = 6,
                        type = "select",
                        name = "Display Order",
                        values = {
                            ["spells"] = "Cooldowns First",
                            ["drs"] = "DRs First",
                        },
                        get = function(info)
                            return E.db.BONK.General.Order
                        end,
                        set = function(info, value)
                            E.db.BONK.General.Order = value
                            BONK:Update()
                        end,
                        disabled = function()
                            return not (E.db.BONK.CD.Position == E.db.BONK.DR.Position)
                        end,
                    },
                    spacer1 = {
                        order = 7,
                        type = 'description',
                        name = ''
                    },
                    spacer2 = {
                        order = 8,
                        type = 'description',
                        name = ''
                    },
                    spacer3 = {
                        order = 9,
                        type = 'description',
                        name = ''
                    },
                    spacer4 = {
                        order = 10,
                        type = 'description',
                        name = ''
                    },
                    spacer5 = {
                        order = 11,
                        type = 'description',
                        name = ''
                    },
                    spacer6 = {
                        order = 12,
                        type = 'description',
                        name = ''
                    },
                    spacer7 = {
                        order = 13,
                        type = 'description',
                        name = ''
                    },
                    spacer8 = {
                        order = 14,
                        type = 'description',
                        name = ''
                    },
                    spacer9 = {
                        order = 15,
                        type = 'description',
                        name = ''
                    },
                    ShowIcons = {
                        order = 16,
                        type = "execute",
                        name = "Display Test Icons",
                        func = function()
                            BONK.BFM:ShowTestIcons()
                        end,
                    },
                    HideIcons = {
                        order = 17,
                        type = "execute",
                        name = "Hide Test Icons",
                        func = function()
                            BONK.BFM:HideTestIcons()
                        end,
                    },
                    Debug = {
                        order = 18,
                        type = "toggle",
                        name = "Debug Mode",
                        desc = "Print debug message",
                        get = function(info)
                            return E.db.BONK.General.Debug
                        end,
                        set = function(info, value)
                            E.db.BONK.General.Debug = value
                        end,
                    },
                },
            },
            Trinket = {
                order = 2,
                type = "group",
                name = "Trinket",
                args = {
                    Position = {
                        order = 1,
                        type = "select",
                        name = "Position",
                        values = {
                            ["RIGHT"] = "RIGHT",
                            ["LEFT"] = "LEFT",
                        },
                        get = function(info)
                            return E.db.BONK.Trinket.Position
                        end,
                        set = function(info, value)
                            E.db.BONK.Trinket.Position = value
                            BONK:Update()
                        end,
                    },
                    TimerFontSize = {
                        order = 2,
                        type = "range",
                        name = "Timer Font Size",
                        min = 0, max = 30, step = 1,
                        get = function(info)
                            return E.db.BONK.Trinket.TimerFontSize
                        end,
                        set = function(info, value)
                            E.db.BONK.Trinket.TimerFontSize = value
                            BONK:Update()
                        end,
                    },
                    spacer1 = {
                        order = 3,
                        type = 'description',
                        name = ''
                    },
                    IconSize = {
                        order = 4,
                        type = "range",
                        name = "Icon Size",
                        min = 0.1, max = 2, step = 0.01,
                        get = function(info)
                            return E.db.BONK.Trinket.IconSize
                        end,
                        set = function(info, value)
                            E.db.BONK.Trinket.IconSize = value
                            BONK:Update()
                        end,
                    },
                    SeparatorX = {
                        order = 5,
                        type = "range",
                        name = "Separator Width",
                        min = 0, max = 100, step = 1,
                        get = function(info)
                            return E.db.BONK.Trinket.SeparatorX
                        end,
                        set = function(info, value)
                            E.db.BONK.Trinket.SeparatorX = value
                            BONK:Update()
                        end,
                    },
                },
            },
            CD = {
                order = 3,
                type = "group",
                name = "Cooldowns",
                args = {
                    Position = {
                        order = 1,
                        type = "select",
                        name = "Position",
                        values = {
                            ["RIGHT"] = "RIGHT",
                            ["LEFT"] = "LEFT",
                        },
                        get = function(info)
                            return E.db.BONK.CD.Position
                        end,
                        set = function(info, value)
                            E.db.BONK.CD.Position = value
                            BONK:Update()
                        end,
                    },
                    TimerFontSize = {
                        order = 2,
                        type = "range",
                        name = "Timer Font Size",
                        min = 0, max = 30, step = 1,
                        get = function(info)
                            return E.db.BONK.CD.TimerFontSize
                        end,
                        set = function(info, value)
                            E.db.BONK.CD.TimerFontSize = value
                            BONK:Update()
                        end,
                    },
                    spacer1 = {
                        order = 3,
                        type = 'description',
                        name = ''
                    },
                    IconSize = {
                        order = 4,
                        type = "range",
                        name = "Icon Size",
                        min = 0.1, max = 1, step = 0.01,
                        get = function(info)
                            return E.db.BONK.CD.IconSize
                        end,
                        set = function(info, value)
                            E.db.BONK.CD.IconSize = value
                            BONK:Update()
                        end,
                    },
                    SeparatorX = {
                        order = 5,
                        type = "range",
                        name = "Separator Width",
                        min = 0, max = 100, step = 1,
                        get = function(info)
                            return E.db.BONK.CD.SeparatorX
                        end,
                        set = function(info, value)
                            E.db.BONK.CD.SeparatorX = value
                            BONK:Update()
                        end,
                    },
                    PaddingX = {
                        order = 6,
                        type = "range",
                        name = "Horizontal Padding",
                        min = 0, max = 100, step = 1,
                        get = function(info)
                            return E.db.BONK.CD.PaddingX
                        end,
                        set = function(info, value)
                            E.db.BONK.CD.PaddingX = value
                            BONK:Update()
                        end,
                    },
                },
            },
            DR = {
                order = 4,
                type = "group",
                name = "DRs",
                args = {
                    Position = {
                        order = 1,
                        type = "select",
                        name = "Position",
                        values = {
                            ["RIGHT"] = "RIGHT",
                            ["LEFT"] = "LEFT",
                        },
                        get = function(info)
                            return E.db.BONK.DR.Position
                        end,
                        set = function(info, value)
                            E.db.BONK.DR.Position = value
                            BONK:Update()
                        end,
                    },
                    TimerFontSize = {
                        order = 2,
                        type = "range",
                        name = "Timer Font Size",
                        min = 0, max = 30, step = 1,
                        get = function(info)
                            return E.db.BONK.DR.TimerFontSize
                        end,
                        set = function(info, value)
                            E.db.BONK.DR.TimerFontSize = value
                            BONK:Update()
                        end,
                    },
                    DRFontSize = {
                        order = 3,
                        type = "range",
                        name = "DR Font Size",
                        min = 0, max = 40, step = 1,
                        get = function(info)
                            return E.db.BONK.DR.DRFontSize
                        end,
                        set = function(info, value)
                            E.db.BONK.DR.DRFontSize = value
                            BONK:Update()
                        end,
                    },
                    IconSize = {
                        order = 4,
                        type = "range",
                        name = "Icon Size",
                        min = 0.1, max = 1, step = 0.01,
                        get = function(info)
                            return E.db.BONK.DR.IconSize
                        end,
                        set = function(info, value)
                            E.db.BONK.DR.IconSize = value
                            BONK:Update()
                        end,
                    },
                    SeparatorX = {
                        order = 5,
                        type = "range",
                        name = "Separator Width",
                        min = 0, max = 100, step = 1,
                        get = function(info)
                            return E.db.BONK.DR.SeparatorX
                        end,
                        set = function(info, value)
                            E.db.BONK.DR.SeparatorX = value
                            BONK:Update()
                        end,
                    },
                    PaddingX = {
                        order = 6,
                        type = "range",
                        name = "Horizontal Padding",
                        min = 0, max = 100, step = 1,
                        get = function(info)
                            return E.db.BONK.DR.PaddingX
                        end,
                        set = function(info, value)
                            E.db.BONK.DR.PaddingX = value
                            BONK:Update()
                        end,
                    },
                },
            },
		},
	}
end

function BONK:Print(message)
    if E.db.BONK.General.Debug and E.db.BONK.General.Debug == true then
        print(message)
    end
end

function BONK:Initialize()
    BONK:Print("Bonkers Initializing")
    self.initialized = true
	--Register plugin so options are properly inserted when config is loaded

	EP:RegisterPlugin(addonName, BONK.InsertOptions)
    self.BFM:Initialize()
    self.BCH:Initialize()
    self.BZT:Initialize()
end

E:RegisterModule(addonName) --Register the module with ElvUI. ElvUI will now call BONK:Initialize() when ElvUI is ready to load our plugin.