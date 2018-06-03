local BONK, E, L, V, P, G = unpack(select(2, ...))

local CreateFrame = CreateFrame

------
-- BONK:NewEventHandler
------
function BONK:NewEventHandler()
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
        self.handler.events[event] = func or event
        self.handler:RegisterEvent(event)
    end

    ns["UnregisterEvent"] = function(self, event, func)
        self.handler.events[event] = nil
        self.handler:UnregisterEvent(event)
    end

    ns["UnregisterAllEvents"] = function(self, event, func)
        self.handler.events = {}
        self.handler:UnregisterAllEvents()
    end

    ns.modules = {}

    ns["ModuleCallback"] = function(self, module, func)
        if type(self[func]) == "function" then
            self[func](self, module)
        end

        if type(module[func]) == "function" then
            module[func](module, self)
        end
    end

    ns["FindModule"] = function(self, module)
        local index = nil
        for i, mod in ipairs(self.modules) do
            if mod == module then
                index = i
                break
            end
        end

        return index
    end

    ns["AddModule"] = function(self, module)
        local index = self:FindModule(module)

        if not index then
            table.insert(self.modules, module)
            self:ModuleCallback(module, "ModuleAdded")
        end
    end

    ns["RemoveModule"] = function(self, module)
        local index = self:FindModule(module)

        if index then
            table.remove(self.modules, index)
            self:ModuleCallback(module, "ModuleRemoved")
        end
    end

    return ns
end
