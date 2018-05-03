local BONK, E, L, V, P, G = unpack(select(2, ...))
local DRData = LibStub("DRData-1.0")

local BCH = BONK:NewEventHandler()
BONK.BCH = BCH

------
-- BCH:Initialize
------
function BCH:Initialize()
    self.db = OmniBar.db
    self.key = "OmniBar"..OmniBar.index-1
    self.cooldowns = db.cooldowns
    self.settings = db.profile.bars[self.key]
end

------
-- BCH:Start
------
function BCH:Start()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
	self:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
end

------
-- BCH:Stop
------
function BCH:Stop()
    self:UnregisterAllEvents()
end

------
-- BCH:IsHostile
------
function BCH:IsHostile(flags)
    if bit.band(flags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0 then
        return true
    else
        return false
    end
end

------
-- BCH:ParseCDEvent
------
function BCH:ParseCDEvent(sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID)
    if self:IsHostile(sourceFlags) == false then
        if spellID == 59752 or spellID == 42292 or spellID == 195710 or spellID == 208683 or spellID == 59752 or spellID == 20589 or spellID == 20594 or spellID == 7744 then
            BONK:Party_ShowSpellFrame(spellID, sourceName, sourceGUID, sourceFlags)
        elseif OmniBar.cooldowns[spellID] then
            if (OmniBar_IsSpellEnabled(f, spellID)) then
                BONK:Party_ShowSpellFrame(spellID, sourceName, sourceGUID, sourceFlags)
            end
        end
    end
end

------
-- BCH:ParseDREvent
------
function BCH:ParseDREvent(sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID)
    if destName == UnitName("player") or IsInGroup(destGUID) then
        local drCat = DRData:GetSpellCategory(spellID)
        if drCat then
            if self:IsHostile(sourceFlags) == true then
                BONK:Party_ShowDRFrame(drCat, spellID, destName, destGUID, destFlags)
            end
        end
    end
end

------
-- BCH:COMBAT_LOG_EVENT_UNFILTERED
------
function BCH:COMBAT_LOG_EVENT_UNFILTERED(self, event, ...)
    local _, eventType, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags,_, spellID = ...

    if (eventType == "SPELL_CAST_SUCCESS" or eventType == "SPELL_AURA_APPLIED") then
        self:ParseCDEvent(sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID)
    elseif (eventType == "SPELL_AURA_REFRESH" or eventType == "SPELL_AURA_REMOVED") then
        self:ParseDREvent(sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID)
    end
end

------
-- BCH:ARENA_COOLDOWNS_UPDATE
------
function BCH:ARENA_COOLDOWNS_UPDATE(event, unit)
    if not unit then return end

    C_PVP.RequestCrowdControlSpell(unit)
    local spellID, startTime, duration = C_PVP.GetArenaCrowdControlInfo(unit)

    BONK:Print("ARENA_COOLDOWNS_UPDATE", unit, spellID, duration)
end

------
-- BCH:ARENA_CROWD_CONTROL_SPELL_UPDATE
------
function BCH:ARENA_CROWD_CONTROL_SPELL_UPDATE(event, unit, spellID)
    if not unit then return end

    BONK:Print("ARENA_CROWD_CONTROL_SPELL_UPDATE", unit, spellID)
end
