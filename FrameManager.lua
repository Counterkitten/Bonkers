local BONK, E, L, V, P, G = unpack(select(2, ...))
local UF = E:GetModule("UnitFrames")

local GetNumGroupMembers = GetNumGroupMembers

local BFM = BONK:NewEventHandler()
BONK.BFM = BFM

------
-- BFM:Initialize
------
function BFM:Initialize()
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
function BFM:Start(isTest)
    if self.running == false then
        self.running = true
        self:RegisterEvent("GROUP_ROSTER_UPDATE")
        self:RegisterEvent("UNIT_NAME_UPDATE", "GROUP_ROSTER_UPDATE")
        self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", "GROUP_ROSTER_UPDATE")

        self:AssignPartyFrames()
        self:AssignArenaFrames(isTest)
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
    self:GetPartySpecs()
end

------
-- BFM:GetPartySpecs
------
function BFM:GetPartySpecs()
    for i = 1, self:GroupSize(), 1 do
        local frame = self.party[i]
        if (not frame.specID or frame.specID == 1) and frame.unit and frame.GUID ~= UnitGUID("player") then
            BONK:Print("Getting spec", frame.unit)
            self:RegisterEvent("INSPECT_READY")
            NotifyInspect(frame.unit)
            return
        end
    end
end

------
-- BFM:AssignArenaFrames
------
function BFM:AssignArenaFrames(isTest)
    for i = 1, 5, 1 do
        local uf = UF["arena"..i]
        if uf then
            if isTest then
                self:AssignGroupFrame(uf, self.arena, i)
            else
                self:AssignGroupFrame(uf, self.arena)
            end
        end
    end
end

------
-- BFM:AssignFrame
------
function BFM:AssignGroupFrame(unitFrame, group, testi)
    if not unitFrame or not unitFrame.unit then return end

    local GUID = UnitGUID(unitFrame.unit)
    if not GUID then return end
    if testi then
        GUID = GUID..testi
    end

    if self.map[GUID] then
        self.map[GUID]:UpdateParent(unitFrame)
    else
        local frame = self:FindFreeFrame(group)
        if not frame then
            self:ReleaseAllFrames()
            self:AssignPartyFrames()
            self:AssignArenaFrames()
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
        frame:RefreshSettings()
    end
end

------
-- BFM:ShowTestIcons
------
function BFM:ShowTestIcons()
    if self.running == false then
        if E.db.unitframe.units['arena']['enable'] then
            UF:ToggleForceShowGroupFrames('arena', 3)
            self.showingArenaTest = true
        end
        self:Start(true)
        BONK.BCH:Start()
    end

    for _,frame in pairs(self.map) do
        frame:HandleCast("trinket", 208683, GetTime(), 600, nil, nil, true)
        frame:HandleCast("spells", 136, GetTime(), 600, nil, nil, true)
        frame:HandleCast("spells", 79140, GetTime(), 600, nil, nil, true)
        frame:HandleCast("spells", 206491, GetTime(), 600, nil, nil, true)
        frame:HandleCast("spells", 211048, GetTime(), 600, nil, nil, true)
        frame:HandleCast("spells", 12042, GetTime(), 600, nil, {duration = 180, expires = GetTime()+120, canSteal = true})
        frame:HandleCast("spells", 212552, GetTime(), 600, nil, {duration = 180, expires = GetTime()+178})
        frame:HandleCast("drs", 33786, GetTime(), 600, "disorient")
        frame:HandleCast("drs", 3355, GetTime(), 600, "incapacitate")
    end
end

------
-- BFM:HideTestIcons
------
function BFM:HideTestIcons()
    if self.showingArenaTest == true then
        UF:ToggleForceShowGroupFrames('arena', 3)
        self.showingArenaTest = false
    end
    self:Stop()
    BONK.BCH:Stop()
end

------
-- BFM:GROUP_ROSTER_UPDATE
------
function BFM:GROUP_ROSTER_UPDATE(event, a)
    self:AssignPartyFrames()
    self:AssignArenaFrames()
end

------
-- BFM:INSPECT_READY
------
function BFM:INSPECT_READY(_, GUID)
    local frame = self:GetUnitFrame(GUID)
    local specID = GetInspectSpecialization(frame.unit)
    if specID then
        frame.specID = specID
    end
    BONK:Print(frame.specID)
    self:UnregisterEvent("INSPECT_READY")
    self:GetPartySpecs()
end
