local BONK, E, L, V, P, G = unpack(select(2, ...))
local DRData = LibStub("DRData-1.0")

local CreateFrame = CreateFrame

function BONK:InitOmni()
    local db = OmniBar.db
    local key = "OmniBar"..OmniBar.index-1

    local f = CreateFrame("Frame")
    f.key = key
    f.cooldowns = db.cooldowns
    f.settings = db.profile.bars[key]
    f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    f:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    f:RegisterEvent("UNIT_NAME_UPDATE")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "UNIT_NAME_UPDATE" then
            BONK:Group_Roster_Update()
        end
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags,_, spellID = ...
            if (event == "SPELL_CAST_SUCCESS" or event == "SPELL_AURA_APPLIED") and (sourceName == UnitName("player") or IsInGroup(sourceGUID)) then
                if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) ~= 0 or bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER or bit.band(sourceFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) == COMBATLOG_OBJECT_CONTROL_PLAYER then
                    if spellID == 59752 or spellID == 42292 or spellID == 195710 or spellID == 208683 or spellID == 59752 or spellID == 20589 or spellID == 20594 or spellID == 7744 then
                        BONK:Party_ShowSpellFrame(spellID, sourceName, sourceGUID, sourceFlags)
                    elseif OmniBar.cooldowns[spellID] then
                        if (OmniBar_IsSpellEnabled(f, spellID)) then
                            BONK:Party_ShowSpellFrame(spellID, sourceName, sourceGUID, sourceFlags)
                        end
                    end
                end

                -- Check if we need to reset any cooldowns
                -- if resets[spellID] then
                --     for i = 1, #self.active do
                --         if self.active[i] and self.active[i].spellID and self.active[i].sourceGUID and self.active[i].sourceGUID == sourceGUID and self.active[i].cooldown:IsVisible() then
                --             -- cooldown belongs to this source
                --             for j = 1, #resets[spellID] do
                --                 if resets[spellID][j] == self.active[i].spellID then
                --                     self.active[i].cooldown:Hide()
                --                     OmniBar_CooldownFinish(self.active[i].cooldown, true)
                --                     return
                --                 end
                --             end
                --         end
                --     end
                -- end
            elseif (event == "SPELL_AURA_REFRESH" or event == "SPELL_AURA_REMOVED") and (destName == UnitName("player") or IsInGroup(destGUID)) then
                local drCat = DRData:GetSpellCategory(spellID)
                if drCat then
                    if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0 then
                        BONK:Party_ShowDRFrame(drCat, spellID, destName, destGUID, destFlags)
                    end
                end
            end

            -- if event == "SPELL_CAST_SUCCESS" or event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" or event == "SPELL_AURA_REMOVED" then
            --     if destName == UnitName("player") or sourceName == UnitName("player") or IsInGroup(destGUID) or IsInGroup(sourceGUID) then
            --         BONK:Update_CooldownFrames()
            --     end
            -- end
        end
        if event == "ZONE_CHANGED_NEW_AREA" then
            local _, zone = IsInInstance()
        end
        -- elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" or event == "ARENA_OPPONENT_UPDATE" then
        --     for i = 1, 5 do
        --         local specID = GetArenaOpponentSpec(i)
        --         if specID and specID > 0 then
        --             local class = select(6, GetSpecializationInfoByID(specID))
        --
        --             OmniBar_AddIconsByClass(self, class, i, specID)
        --         end
        --     end
        -- end
    end)
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end