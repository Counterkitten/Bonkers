local BONK, E, L, V, P, G = unpack(select(2, ...))
local BZT = BONK.BZT
local BCH = BONK.BCH
local BKB = {}
BONK.BKB = BKB

------
-- BKB:Initialize
------
function BKB:Initialize()
    self.running = false
    if self:IsEnabled() then
        BZT:AddModule(self)
    end
end

------
-- BKB:Update
------
function BKB:Update()
    if self:IsEnabled() then
        BZT:AddModule(self)
    else
        BZT:RemoveModule(self)
    end
end

------
-- BKB:Start
------
function BKB:Start()
    self.running = true
end

------
-- BKB:Stop
------
function BKB:Stop()
    self.running = false
end

------
-- BKB:IsEnabled
------
function BKB:IsEnabled()
    return E.db.BKB.Party.Enabled == true or E.db.BKB.Arena.Enabled == true
end

------
-- BKB:IsRunning
------
function BKB:IsRunning()
    return self.running
end
