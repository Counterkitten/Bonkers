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
    self.running = false

    self:InitFrames(self.party, false)
    self:InitFrames(self.arena, true)
end

------
-- BFM:InitFrames
------
function BFM:InitFrames(group, hostile)
    for i = 1, 5, 1 do
        group[i] = BONK.NewFrame(hostile)
    end
end

------
-- BFM:Start
------
function BFM:Start()
    if self.running == false then
        BONK:Print("Starting BFM")
        self.running = true
        self:RegisterEvent("GROUP_ROSTER_UPDATE")
        self:RegisterEvent("UNIT_NAME_UPDATE", "GROUP_ROSTER_UPDATE")
        self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", "GROUP_ROSTER_UPDATE")

        self:AssignPartyFrames()
    end
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
        self:AssignGroupFrame(uf, self.party)
    end
end

------
-- BFM:AssignArenaFrames
------
function BFM:AssignArenaFrames()
    for unit, group in pairs(UF.groupunits) do
        BONK:Print(unit)
        BONK:Print(group)
    end
end

------
-- BFM:AssignFrame
------
function BFM:AssignGroupFrame(unitFrame, group)
    if not unitFrame or not unitFrame.unit then return end

    local GUID = UnitGUID(unitFrame.unit)
    if not GUID then return end

    if self.map[GUID] then
        self.map[GUID]:UpdateParent(unitFrame)
    else
        local frame = self:FindFreeFrame(group)
        if not frame then
            self:ReleaseAllFrames()
            self:AssignPartyFrames()
            --self:AssignArenaFrames()
        end

        frame:AssignFrame(unitFrame, GUID)
        self.map[GUID] = frame
    end
end

------
-- BFM:FindFreeFrame
------
function BFM:FindFreeFrame(group)
    local found = nil
    for i = 1, 5, 1 do
        if not group[i]:IsAssigned() then
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
        self.party[i]:Release()
        self.arena[i]:Release()
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
-- BFM:RefreshSettings
------
function BFM:RefreshSettings()
    for _,frame in pairs(self.map) do
        frame:UpdateIcons(frame)
    end
end

------
-- BFM:ShowTestIcons
------
function BFM:ShowTestIcons()
    if self.running == false then
        self:Start()
    end

    for _,frame in pairs(self.map) do
        frame:HandleCast("trinket", 208683, GetTime(), 600)
        frame:HandleCast("spells", 136, GetTime(), 600)
        frame:HandleCast("spells", 79140, GetTime(), 600)
        frame:HandleCast("drs", 33786, GetTime(), 600, "disorient")
        frame:HandleCast("drs", 3355, GetTime(), 600, "incapacitate")
    end
end

------
-- BFM:HideTestIcons
------
function BFM:HideTestIcons()
    self:Stop()
end

------
-- BFM:GROUP_ROSTER_UPDATE
------
function BFM:GROUP_ROSTER_UPDATE(event, a)
    BONK:Print(event)
    BONK:Print(a)
    self:AssignPartyFrames()
end
