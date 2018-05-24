local BONK, E, L, V, P, G = unpack(select(2, ...))
local DRData = LibStub("DRData-1.0")

local BCH = BONK:NewEventHandler()
BONK.BCH = BCH

------
-- BCH:Initialize
------
function BCH:Initialize()
    self.running = false
end

------
-- BCH:Start
------
function BCH:Start()
    BONK:Print("Starting BCH")
    if self.running == false then
        self.running = true
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        --self:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
    	--self:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
    end
end

------
-- BCH:Stop
------
function BCH:Stop()
    self.running = false
    self:UnregisterAllEvents()
end

------
-- BCH:IsHostile
------
function BCH:IsHostile(flags)
    if bit.band(flags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0 then
        return true
    end
    return false
end

------
-- BCH:ParseCDEvent
------
function BCH:ParseCDEvent(sourceGUID, sourceFlags, destGUID, destFlags, spellID)
    if BONK.BFM:GetUnitFrame(sourceGUID) then
        if spellID == 59752 or spellID == 42292 or spellID == 195710 or spellID == 208683 or spellID == 59752 or spellID == 20589 or spellID == 20594 or spellID == 7744 then
            self:DispatchCast(sourceGUID, "trinket", spellID)
        elseif BCD.cooldowns[spellID] then
            if self:IsSpellEnabled(spellID, sourceFlags) then
                BONK:Print("Dispatching "..spellID)
                local auraInfo = self:GetAuraInfo(sourceGUID, sourceFlags, spellID, true)
                if not auraInfo then
                    auraInfo = self:GetAuraInfo(destGUID, destFlags, spellID)
                    if auraInfo and auraInfo.unitCaster and UnitGUID(auraInfo.unitCaster) ~= sourceGUID then
                        aureInfo = nil
                    end
                end

                self:DispatchCast(sourceGUID, "spells", spellID, nil, nil, auraInfo)
            end
        end
    end
end

------
-- BCH:ParseCDEnded
------
function BCH:ParseCDEnded(sourceGUID, spellID)
    local name, t, icon = GetSpellInfo(spellID)
    local target = BONK.BFM:GetUnitFrame(sourceGUID)
    if not target then return end

    target:HideAura(spellID)
end

------
-- BCH:ParseDREvent
------
function BCH:ParseDREvent(sourceFlags, destGUID, destFlags, spellID)
    if BONK.BFM:GetUnitFrame(destGUID) then
        local drCat = DRData:GetSpellCategory(spellID)
        if drCat then
            if self:IsHostile(destFlags) ~= self:IsHostile(sourceFlags) then
                local duration = DRData:GetResetTime()
                self:DispatchCast(destGUID, "drs", spellID, duration, drCat)
            end
        end
    end
end

------
-- BCH:DispatchCast
------
function BCH:DispatchCast(targetGUID, type, spellID, duration, category, auraInfo)
    local startTime = GetTime()
    local target = BONK.BFM:GetUnitFrame(targetGUID)
    if not target then return end

    if not duration then
        if type == "spells" then
            duration = self:GetSpellCooldown(target, spellID)
        elseif type == "trinket" then
            duration = self:GetTrinketCooldown(spellID)
        end
    end

    target:HandleCast(type, spellID, startTime, duration, category, auraInfo)
end

------
-- BCH:IsSpellEnabled
------
function BCH:IsSpellEnabled(spellID, flags)
    if not spellID or not flags then return end
    local db = E.db.BONK.Party.Track
    if self:IsHostile(flags) then
        db = E.db.BONK.Arena.Track
    end

    -- Check for an explicit rule
    local spell = "spell"..spellID
    local parent = nil
    if BCD.cooldowns[spellID] and BCD.cooldowns[spellID].parent then
        parent = BCD.cooldowns[spellID].parent
    end

    if type(db[spell]) == "boolean" or (parent and type(db["spell"..parent]) == "boolean") then
        if db[spell] or db["spell"..parent] then
            return true
        end
    end
    return nil
end

------
-- BCH:GetSpellCooldown
------
function BCH:GetSpellCooldown(target, spellID)
    local duration = 0

    local cd = BCD.cooldowns[spellID]
    if cd.duration then
        duration = cd.duration
    elseif cd.parent then
        duration = BCD.cooldowns[cd.parent].duration
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
-- BCH:GetAuraInfo
------
function BCH:GetAuraInfo(targetGUID, flags, spellID, showSteal)
    local target = BONK.BFM:GetUnitFrame(targetGUID)
    if not target then return nil end

    local name, _, _ = GetSpellInfo(spellID)
    local _, _, _, _, _, duration, expirationTime, unitCaster, canStealOrPurge = UnitAura(target:GetUnitName(), name)
    if not expirationTime then return nil end

    local info = {
        duration = duration,
        expires = expirationTime,
        caster = unitCaster
    }

    if showSteal and canStealOrPurge then
        info["canSteal"] = true
    end

    return info
end

------
-- BCH:COMBAT_LOG_EVENT_UNFILTERED
------
function BCH:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    local _, eventType, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags,_, spellID = ...
    if (eventType == "SPELL_CAST_SUCCESS" or eventType == "SPELL_AURA_APPLIED") then
        self:ParseCDEvent(sourceGUID, sourceFlags, destGUID, destFlags, spellID)
    elseif (eventType == "SPELL_AURA_REFRESH" or eventType == "SPELL_AURA_REMOVED") then
        self:ParseCDEnded(sourceGUID, spellID)
        self:ParseDREvent(sourceFlags, destGUID, destFlags, spellID)
    end
end

------
-- BCH:ARENA_COOLDOWNS_UPDATE
------
function BCH:ARENA_COOLDOWNS_UPDATE(event, unit)
    if not unit then return end

    C_PvP.RequestCrowdControlSpell(unit)
    local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unit)

    BONK:Print("ARENA_COOLDOWNS_UPDATE "..unit.." "..spellID.." "..duration)
end

------
-- BCH:ARENA_CROWD_CONTROL_SPELL_UPDATE
------
function BCH:ARENA_CROWD_CONTROL_SPELL_UPDATE(event, unit, spellID)
    if not unit then return end

    BONK:Print("ARENA_CROWD_CONTROL_SPELL_UPDATE"..unit.." "..spellID)
end
