local BONK, E, L, V, P, G = unpack(select(2, ...))

local IsInInstance = IsInInstance

local BZT = BONK:NewEventHandler()
BONK.BZT = BZT

------
-- BZT:Initialize
------
function BZT:Initialize(modules)
    self.instanceType = "none"
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("ADDON_LOADED", "ZONE_CHANGED_NEW_AREA")
    self.modules = modules
end

------
-- BZT:ModuleAdded
------
function BZT:ModuleAdded(module)
    BONK:Print("Module Added")
    self:CheckArea()
end

------
-- BZT:ModuleRemoved
------
function BZT:ModuleRemoved(module)
    BONK:Print("Module Removed")
    if module:IsRunning() then
        module:Stop()
    end
end

------
-- BZT:InArena
------
function BZT:InArena()
    return self.instanceType == "arena"
end

------
-- BZT:CheckArea
------
function BZT:CheckArea(event)
    for _, module in ipairs(self.modules) do
        if self:InArena() == true then
            if not module:IsRunning() then
                module:Start()
            end
        else
            if module:IsRunning() then
                module:Stop()
            end
        end
    end
end

------
-- BZT:ZONE_CHANGED_NEW_AREA
------
function BZT:ZONE_CHANGED_NEW_AREA(event)
    local _, instanceType = IsInInstance()
    self.instanceType = instanceType

    self:CheckArea(event)
end
