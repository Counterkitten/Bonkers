local BONK, E, L, V, P, G = unpack(select(2, ...))
local UF = E:GetModule("UnitFrames")

local GetNumGroupMembers = GetNumGroupMembers

local db = E.db.BONK

local BFM = BONK:NewEventHandler()
BONK.BFM = BFM

------
-- BFM:Initialize
------
function BFM:Initialize()
    BONK:Print("BFM Initializing")
    self.party = {}
    self.arena = {}
    self.map = {}

    self:InitFrames(self.party, false)
    self:InitFrames(self.arena, true)
end

------
-- BFM:InitFrames
------
function BFM:InitFrames(group, hostile)
    for i = 1, 5, 1 do
        group[i] = BONK:NewFrame(hostile)
    end
end

------
-- BFM:Start
------
function BFM:Start()
    self.running = true
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    -- self:RegisterEvent("ARENA_OPPONENT_UPDATE")
    -- self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")

    self:AssignPartyFrames()
end

------
-- BFM:Stop
------
function BFM:Stop()
    self.running = false
    self:UnregisterAllEvents()
    self:ReleaseAllFrames()
end

------
-- BFM:AssignPartyFrames
------
function BFM:AssignPartyFrames()
    for i = 1, self:GroupSize(), 1 do
        local uf = UF.headers.party.groups[1][i]
        self:AssignGroupFrame(uf, self.party, i)
    end
end

------
-- BFM:AssignArenaFrames
------
function BFM:AssignArenaFrames()

end

------
-- BFM:AssignFrame
------
function BFM:AssignGroupFrame(unitFrame, group, i)
    if not unitFrame or not unitFrame.unit then return end

    local GUID = UnitGUID(unitFrame.unit)
    if not GUID or self.map[GUID] then return end

    local frame = group[i]
    if frame:IsAssigned(frame) then
        frame = FindFreeFrame(group)

        if not frame then
            E:Print("No frame found, resetting")
            self:ReleaseAllFrames()
            self:AssignPartyFrames()
            self:AssignArenaFrames()
            return
        end
    end

    frame:AssignFrame(frame, unitFrame, hostile)
    self.map[GUID] = frame
end

------
-- BFM:FindFreeFrame
------
function BFM:FindFreeFrame(group)
    local found = nil
    for i = 1, 5, 1 do
        if group[i]:IsAssigned(group[i]) then
            found = group[i]
            break
        end
    end

    return found
end

------
-- BFM:ReleaseAllFrames
------
function BFM:ReleaseAllFrames()
    for i = 1, 5, 1 do
        self.party[i]:Release(self.party[i])
        self.arena[i]:Release(self.arena[i])
    end
    self.map = {}
end

------
-- BFM:GetSpecID
------
function BFM:GetUnitFrame(GUID)
    if self.map[GUID] then
        return self.map[GUID]
    end
end

------
-- BFM:GroupSize
------
function BFM:GroupSize()
    return max(min(GetNumGroupMembers(), 5), 1)
end

------
-- BFM:GROUP_ROSTER_UPDATE
------
function BFM:GROUP_ROSTER_UPDATE()
    print(self.started)
    self:AssignPartyFrames()
end

------
-- BFM:ARENA_OPPONENT_UPDATE
------
function BFM:ARENA_OPPONENT_UPDATE()

end

------
-- BFM:ARENA_PREP_OPPONENT_SPECIALIZATIONS
------
function BFM:ARENA_PREP_OPPONENT_SPECIALIZATIONS()

end