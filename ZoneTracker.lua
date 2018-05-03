local BONK, E, L, V, P, G = unpack(select(2, ...))

local BZT = BONK:NewEventHandler()
BONK.BZT = BZT

local IsInInstance = IsInInstance

------
-- BONK:InitZoneTracker
------
function BONK:InitZoneTracker()
    BZT.instanceType = "none"
    BZT:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    BZT:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
end

------
-- BZT:InArena
------
function BZT:InArena()
    if E.db.BONK.General.Debug then
        return true
    else
        return self.instanceType == "arena"
    end
end

------
-- BZT:ZONE_CHANGED_NEW_AREA
------
function BZT:ZONE_CHANGED_NEW_AREA()
    local _, instanceType = IsInInstance()

    if instanceType == "arena" then
        if self:InArena() == false then
            BONK.BCH:Start()
            BONK:Group_Roster_Update()
        end
    elseif self:InArena() == true then
        BONK.BCH:Stop()
    end
    self.instanceType = instanceType
end
