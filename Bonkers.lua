--[[
	This is a framework showing how to create a plugin for ElvUI.
	It creates some default options and inserts a GUI table to the ElvUI Config.
	If you have questions then ask in the Tukui lua section: https://www.tukui.org/forum/viewforum.php?f=10
]]

local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local EP = LibStub("LibElvUIPlugin-1.0") --We can use this to automatically insert our GUI tables when ElvUI_Config is loaded.
local coreName, addonTable = ... --See http://www.wowinterface.com/forums/showthread.php?t=51502&p=304704&postcount=2
local _G = _G
local BONK = E:NewModule(coreName, 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0') --Create a plugin within ElvUI and adopt AceHook-3.0, AceEvent-3.0 and AceTimer-3.0. We can make use of these later.
BONK.callbacks = BONK.callbacks or LibStub("CallbackHandler-1.0"):New(BONK)

--Default options
P["BONK"] = BSF:GetDefaults()
P["BKB"] = BSF:GetKBDefaults()

addonTable[1] = BONK
addonTable[2] = E
addonTable[3] = L
addonTable[4] = V
addonTable[5] = P
addonTable[6] = G
_G[coreName] = addonTable
-- _G[kickName] = addonTable

--Function we can call when a setting changes.
--In this case it just checks if "SomeToggleOption" is enabled. If it is it prints the value of "SomeRangeOption", otherwise it tells you that "SomeToggleOption" is disabled.
function BONK:Update()
	self.BFM:RefreshSettings()
end

--This function inserts our GUI table into the ElvUI Config. You can read about AceConfig here: http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
function BONK:InsertOptions()
	E.Options.args.BONK = BSF:GetSettings()
	E.Options.args.BKB = BSF:GetKBSettings()
end

function BONK:Print(...)
    if E.db.BONK and E.db.BONK.General and E.db.BONK.General.Debug and E.db.BONK.General.Debug == true then
        print(...)
    end
end

function BONK.ToggleConfig()
	BONK.DoToggleConfig("BONK")
end

function BONK.ToggleBKBConfig()
	BONK.DoToggleConfig("BKB")
end

function BONK.DoToggleConfig(which)
	E:ToggleConfig()
	if IsAddOnLoaded("ElvUI_Config") then
		local ACD = LibStub("AceConfigDialog-3.0-ElvUI")

		ACD:SelectGroup("ElvUI", which)
	end
end

function BONK:Initialize()
    BONK:Print("Bonkers Initializing")
    self.initialized = true
	--Register plugin so options are properly inserted when config is loaded

    BSF:Initialize(self, self.BKB)
	BCD:Initialize(self, E.db.BONK)
	EP:RegisterPlugin(coreName, BONK.InsertOptions)
    self.BFM:Initialize()
    self.BCH:Initialize()
    self.BZT:Initialize({self.BFM, self.BCH})
	self.BKB:Initialize()

	E:RegisterChatCommand("bonkers", BONK.ToggleConfig)
	E:RegisterChatCommand("bnk", BONK.ToggleConfig)
	E:RegisterChatCommand("bkb", BONK.ToggleBKBConfig)
end

local function InitializeCallback()
	BONK:Initialize()
end

E:RegisterModule(coreName, InitializeCallback) --Register the module with ElvUI. ElvUI will now call BONK:Initialize() when ElvUI is ready to load our plugin.
