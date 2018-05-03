local BONK, E, L, V, P, G = unpack(select(2, ...))
local UF = E:GetModule("UnitFrames")

local GetNumGroupMembers = GetNumGroupMembers

local db = E.db.BONK

local BFM = BONK:NewEventHandler()
BONK.BFM = BFM

------
-- BONK:InitFrameManager
------
function BONK:InitFrameManager()
    BFM.party = {}
    BFM.arena = {}

    for i = 1, 5, 1 do
        local partyUF = BFM:FindUFByIndex("party", i)
        local partyFrame = BUF
        partyFrame:NewFrame(partyFrame, db.Trinket.IconSize)



        BFM.arena[i] =
    end
end

------
-- BFM:Start
------
function BFM:Start()
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    -- self:RegisterEvent("ARENA_OPPONENT_UPDATE")
    -- self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
end

------
-- BFM:Stop
------
function BFM:Stop()
    self:UnregisterAllEvents()
    self:ReleaseAllFrames()
end

------
-- BFM:FindUFByIndex
------
function BFM:FindUFByIndex(type, index)
    local groupSize = max(min(GetNumGroupMembers(), 5), 1)

    for i=1,groupSize,1 do
        local f = UF.headers.party.groups[1][i]
        if f and f.unit and UnitGUID(f.unit) == sourceGUID then
            return f
        end
    end
    return nil
end

------
-- BFM:FindUFByGUID
------
function BFM:FindUFByGUID(type, GUID)
    local groupSize = max(min(GetNumGroupMembers(), 5), 1)

    for i=1,groupSize,1 do
        local f = UF.headers.party.groups[1][i]
        if f and f.unit and UnitGUID(f.unit) == sourceGUID then
            return f
        end
    end
    return nil
end

------
-- BFM:FindUFByGUID
------
function BFM:FindFrame(type, value)