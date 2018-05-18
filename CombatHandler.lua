local BONK, E, L, V, P, G = unpack(select(2, ...))
local DRData = LibStub("DRData-1.0")

local BCH = BONK:NewEventHandler()
BONK.BCH = BCH

------
-- BCH:Initialize
------
function BCH:Initialize()
    BONK:Print("BCH Initializing")
    self.db = OmniBar.db
    self.key = "OmniBar"..OmniBar.index-1
    self.cooldowns = self.db.cooldowns
    self.settings = self.db.profile.bars[self.key]
end

------
-- BCH:Start
------
function BCH:Start()
    BONK:Print("Starting BCH")
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
    end
    return nil
end

------
-- BCH:ParseCDEvent
------
function BCH:ParseCDEvent(sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID)
    if not self:IsHostile(sourceFlags) then
        if spellID == 59752 or spellID == 42292 or spellID == 195710 or spellID == 208683 or spellID == 59752 or spellID == 20589 or spellID == 20594 or spellID == 7744 then
            self:DispatchCast(sourceGUID, "trinket", spellID, nil, nil)
        elseif OmniBar.cooldowns[spellID] then
            if (OmniBar_IsSpellEnabled(self, spellID)) then
                BONK:Print("Dispatching "..spellID)
                self:DispatchCast(sourceGUID, "spells", spellID)
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
            if self:IsHostile(sourceFlags) then
                local duration = DRData:GetResetTime()
                self:DispatchCast(destGUID, "drs", spellID, duration, drCat)
            end
        end
    end
end

------
-- BCH:DispatchCast
------
function BCH:DispatchCast(targetGUID, type, spellID, duration, category)
    local startTime = GetTime()
    local target = BONK.BFM:GetUnitFrame(targetGUID)

    if not duration then
        if type == "spells" then
            duration = self:GetSpellCooldown(target, spellID)
        elseif type == "trinket" then
            duration = self:GetTrinketCooldown(spellID)
        end
    end

    print(duration)

    target:HandleCast(type, spellID, startTime, duration, category)
end

------
-- BCH:GetSpellCooldown
------
function BCH:GetSpellCooldown(target, spellID)
    local duration = 0

    local cd = OmniBar.cooldowns[spellID]
    if cd.duration then
        duration = cd.duration
    elseif cd.parent then
        duration = OmniBar.cooldowns[cd.parent].duration
    end

    if type(duration) == "table" then
        if target.specID and duration[target.specID] then
            duration = duration[target.specID]
        else
            duration = duration.default
        end
    end

    return duration
end

------
-- BCH:GetTrinketCooldown
------
function BCH:GetTrinketCooldown(target, spellID)
    if spellID == 59752 or spellID == 208683 then
        -- PVP trinkets or Gladiator's Medallion
        return 120
	elseif spellID == 195710 then
        -- Honorable Medallion
		return 180
    elseif spellID == 42292 then
        -- Adaption
        return 60
	else
        -- Every Man For Himself or Escape Artist or Stoneform or Will of the Forsaken
		return 30
	end
end

------
-- BCH:COMBAT_LOG_EVENT_UNFILTERED
------
function BCH:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    local _, eventType, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags,_, spellID = ...
    if (eventType == "SPELL_CAST_SUCCESS" or eventType == "SPELL_AURA_APPLIED") then
        print("spam")
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