local BONK, E, L, V, P, G = unpack(select(2, ...))

local CreateFrame = CreateFrame

------
-- BONK:NewEventHandler
------
function BONK:NewEventHandler()
    local ns = {}
    ns.zoneHandler = CreateFrame("Frame")
    ns.zoneHandler.events = {}
    ns.zoneHandler:SetScript("OnEvent", function(self, event, ...)
        local func = self.events[event]
        if type(ns[func]) == "function" then
            ns[func](ns, event, ...)
        end
    end)

    ns["RegisterEvent"] = function(event, func)
        self.combatHandler.events[event] = func or event
        self.combatHandler:RegisterEvent(event)
    end

    ns["UnregisterEvent"] = function(event, func)
        self.combatHandler.events[event] = nil
        self.combatHandler:UnregisterEvent(event)
    end

    ns["RegisterEvent"] = function(event, func)
        self.combatHandler.events = {}
        self.combatHandler:UnregisterAllEvents()
    end

    return ns
end
