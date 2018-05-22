local BONK, E, L, V, P, G = unpack(select(2, ...))

local IsInInstance = IsInInstance

local BZT = BONK:NewEventHandler()
BONK.BZT = BZT

------
-- BZT:Initialize
------
function BZT:Initialize()
    self.instanceType = "none"
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("ADDON_LOADED", "ZONE_CHANGED_NEW_AREA")
end

------
-- BZT:InArena
------
function BZT:InArena()
    return self.instanceType == "arena"
end

------
-- BZT:DisableDebug
------
function BZT:ToggleDebug()
    self:ZONE_CHANGED_NEW_AREA("DEBUG")
end

------
-- BZT:ZONE_CHANGED_NEW_AREA
------
function BZT:ZONE_CHANGED_NEW_AREA(event)
    local _, instanceType = IsInInstance()
    self.instanceType = instanceType

    if self:InArena() == true then
        BONK.BFM:Start()
        BONK.BCH:Start()
    else
        BONK.BFM:Stop()
        BONK.BCH:Stop()
    end
end
