local BONK, E, L, V, P, G = unpack(select(2, ...))

local CreateFrame = CreateFrame

------
-- BONK:NewEventHandler
------
function BONK:NewEventHandler()
    BONK:Print("New EV")
    local ns = {}
    ns.handler = CreateFrame("Frame")
    ns.handler.events = {}
    ns.handler:SetScript("OnEvent", function(self, event, ...)
        local func = self.events[event]
        if type(ns[func]) == "function" then
            ns[func](ns, event, ...)
        end
    end)

    ns["RegisterEvent"] = function(self, event, func)
        ns.handler.events[event] = func or event
        ns.handler:RegisterEvent(event)
    end

    ns["UnregisterEvent"] = function(self, event, func)
        ns.handler.events[event] = nil
        ns.handler:UnregisterEvent(event)
    end

    ns["UnregisterAllEvents"] = function(self, event, func)
        ns.handler.events = {}
        ns.handler:UnregisterAllEvents()
    end

    return ns
end
