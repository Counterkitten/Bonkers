local BONK, E, L, V, P, G = unpack(select(2, ...))
local UF = E:GetModule("UnitFrames")
local DRData = LibStub("DRData-1.0")
local _G = _G

local CreateFrame = CreateFrame
local GetInspectSpecialization = GetInspectSpecialization
local GetNumGroupMembers = GetNumGroupMembers
local GetSpecialization = GetSpecialization
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime

local drTexts = {
    [1] = {"\194\189", 0, 1, 0},
    [0.5] = {"\194\188", 1, 0.65, 0},
    [0.25] = {"%", 1, 0, 0},
    [0] = {"%", 1, 0, 0},
}

------
-- BONK:Party_ConstructFrame
------
function BONK:Party_ConstructFrame(frame)
    frame.trinket = BONK:Party_ConstructFrameIcon(frame, "trinket")
    frame.trinket.texture:SetTexture("Interface\\Icons\\INV_Jewelry_Necklace_37")

    if E.db.BONK.Trinket.Position == "LEFT" then
        frame.trinket:SetPoint("TOPRIGHT", frame, "TOPLEFT", -1 * E.db.BONK.Trinket.SeparatorX, 0)
    else
        frame.trinket:SetPoint("TOPLEFT", frame, "TOPRIGHT", E.db.BONK.Trinket.SeparatorX, 0)
    end
    if E.db.BONK.Trinket.Enabled == true then
        frame.trinket:Show()
    else
        frame.trinket:Hide()
    end

    frame.spell = {}
    frame.dr = {}
    frame.activeSpells = {}
    frame.activeDRs = {}
end

------
-- BONK:Party_ConstructFrameIcon
------
function BONK:Party_ConstructFrameIcon(frame, type)
    return BONK:Party_ConstructFrameIcon(frame, type, nil)
end

------
-- BONK:Party_ConstructFrameIcon
------
function BONK:Party_ConstructFrameIcon(frame, type, IDorValue)
    local name = "Trinket"
    local key = "spellID"
    local size = 1

    if type == "spell" then
        name = "Spell"..IDorValue
        size = E.db.BONK.CD.IconSize
    elseif type == "dr" then
        name = "DR"..IDorValue
        key = "category"
        size = E.db.BONK.DR.IconSize
    else
        key = "isTrinket"
        IDorValue = true
        size = E.db.BONK.Trinket.IconSize
    end

    local icon = CreateFrame('Button', frame:GetName()..name, frame, "ActionButtonTemplate")
    icon[key] = IDorValue
    icon.spacing = E.Spacing
    icon:SetFrameLevel(frame.RaisedElementParent:GetFrameLevel() + 10)

    icon:SetWidth(frame:GetHeight()*size)
    icon:SetHeight(frame:GetHeight()*size)

    icon:SetNormalTexture(nil)
    icon:ClearAllPoints()
    icon.texture = icon:CreateTexture()
    icon.texture:SetAllPoints(icon)
    icon.texture:SetHeight(icon:GetHeight())
    icon.texture:SetWidth(icon:GetWidth())


    icon.cooldown = CreateFrame("Cooldown", name.."Cooldown", icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints(icon)
    icon.cooldown:SetReverse(true)
    icon.cooldown:SetScript("OnCooldownDone", function(cooldown)
        local i = cooldown:GetParent()
        BONK:Reset_CooldownIcon(i)
        BONK:Spell_UpdateIcons(i:GetParent())
        BONK:DR_UpdateIcons(i:GetParent())
    end)

    icon.cdtext = icon.cooldown:CreateFontString(nil, "OVERLAY")
    icon.cdtext:SetJustifyH("CENTER")
    icon.cdtext:SetPoint("CENTER", icon.cooldown)
    icon.cdtext:SetAlpha(0)

    if type == "spell" then
        icon.cdtext:SetFont(E["media"].normFont, E.db.BONK.CD.TimerFontSize, "OUTLINE")
    elseif type == "dr" then
        icon.cdtext:SetFont(E["media"].normFont, E.db.BONK.DR.TimerFontSize, "OUTLINE")
        icon.drtext = icon.cooldown:CreateFontString(nil, "OVERLAY")
        icon.drtext:SetFont(E["media"].normFont, E.db.BONK.DR.DRFontSize, "OUTLINE")
    	icon.drtext:SetJustifyH("RIGHT")
    	icon.drtext:SetPoint("BOTTOMRIGHT", icon.cooldown, -3, 0)
        icon.drtext:SetAlpha(0)
        icon.diminished = 0
    else
        icon.cdtext:SetFont(E["media"].normFont, E.db.BONK.Trinket.TimerFontSize, "OUTLINE")
    end
    icon.reset = 0
    icon.timeLeft = 0

    --E:SetUpAnimGroup(icon)
    --E:RegisterCooldown(icon.cooldown)

    icon.active = false

    return icon
end

------
-- BONK:Party_ShowSpellFrame
------
function BONK:Party_ShowSpellFrame(spellID, sourceName, sourceGUID)
    local duration = 0
    local isTrinket = false
    local normalTexture = nil

    -- PVP trinkets or Gladiator's Medallion
	if spellID == 59752 or spellID == 208683 then
        duration = 120
        isTrinket = true
        local _, _, texture = GetSpellInfo(spellID)
        normalTexture = texture
	end
	-- Honorable Medallion
	if spellID == 195710 then
		duration = 180
        isTrinket = true
        local _, _, texture = GetSpellInfo(spellID)
        normalTexture = texture
	end
    -- Adaption
    if spellID == 42292 then
        duration = 60
        isTrinket = true
        local _, _, texture = GetSpellInfo(spellID)
        normalTexture = texture
    end
	-- Every Man For Himself or Escape Artist or Stoneform or Will of the Forsaken
	if spellID == 59752 or spellID == 20589 or spellID == 20594 or spellID == 7744 then
        if spellID == 195901 then return end
		duration = 30
        isTrinket = true
	end

    local frame = BONK:Party_FindFrame(sourceGUID)
    if not frame then return end

    local icon = nil
    if isTrinket == true then
        icon = frame.trinket
        if icon.timeLeft > duration then return end
        icon.spellID = spellID
    else
        if frame.spell[spellID] then
            icon = frame.spell[spellID]
        else
            icon = BONK:Party_ConstructFrameIcon(frame, "spell", spellID)
            frame.spell[spellID] = icon
        end
    end
    if not icon then return end

    if sourceName == "Test" then
        duration = 560
        icon.isTest = true
    else
        icon.isTest = false
    end

    if normalTexture and not icon.normalTexture then
        icon.normalTexture = normalTexture
    end

    icon:UnregisterAllEvents()

    local _, _, spellTexture = GetSpellInfo(spellID)
    icon.texture:SetTexture(spellTexture)

    if duration == 0 then
        local cd = OmniBar.cooldowns[spellID]
        if cd.duration then
            duration = cd.duration
        elseif cd.parent then
            duration = OmniBar.cooldowns[cd.parent].duration
        end
    end

    if type(duration) == "table" then
        if frame.specID and duration[frame.specID] then
            duration = duration[frame.specID]
        else
            duration = duration.default
        end
    end

    if not duration or duration == 0 then return end

    icon.duration = duration
    icon.timeLeft = duration
    local start = GetTime()
    icon.reset = start + icon.duration

    icon.cooldown:SetSwipeColor(0, 0, 0, 0.5)
    icon.cooldown:SetCooldown(start, duration)

    icon.cdtext:SetAlpha(1)

    if not icon.active or icon.active == false then
        icon.active = true
        if isTrinket == false then
            if OmniBar.cooldowns[spellID] and OmniBar.cooldowns[spellID].default then
                table.insert(frame.activeSpells, 1, icon)
            else
                table.insert(frame.activeSpells, icon)
            end
        end
    end
    icon:SetScript("OnUpdate", function(icon, elapsed)
        BONK:Update_CooldownIcon(icon, elapsed)
    end)
    BONK:Spell_UpdateIcons(frame)
    BONK:DR_UpdateIcons(frame)
end

------
-- BONK:Spell_UpdateIcons
------
function BONK:Spell_UpdateIcons(frame)
    local remove = {}

    if not frame.activeSpells then return end
    for _,icon in pairs(frame.activeSpells) do
        if icon.active == false then
            remove[icon.spellID] = true
        end
    end

    for i = #frame.activeSpells, 1, -1 do
        local icon = frame.activeSpells[i]
        if (remove[icon.spellID]) then
            table.remove(frame.activeSpells, i)
        end
    end

    for i = 1, #frame.activeSpells, 1 do
        local icon = frame.activeSpells[i]
        local paddingX = E.db.BONK.CD.PaddingX
        local paddingY = 0
        local point1 = "TOPRIGHT"
        local point2 = "TOPLEFT"

        local side = E.db.BONK.CD.Position
        local ref = frame
        if i == 1 then
            if frame.trinket and side == E.db.BONK.Trinket.Position then
                ref = frame.trinket
            end

            if side == E.db.BONK.DR.Position then
                if E.db.BONK.General.Stack == true then
                    local op = -1
                    if E.db.BONK.General.Order == "DR" then
                        op = 1
                        point1 = "BOTTOMRIGHT"
                        point2 = "BOTTOMLEFT"
                    end
                    local heightDiff = (frame:GetHeight()/2) - icon:GetHeight()
                    paddingY = op * (heightDiff - E.db.BONK.General.SeparatorY)
                elseif E.db.BONK.General.Order == "DR" and #frame.activeDRs > 0 then
                    ref = frame.activeDRs[#frame.activeDRs]
                    paddingX = paddingX + E.db.BONK.DR.PaddingX
                end
            end
            paddingX = paddingX + E.db.BONK.CD.SeparatorX
        else
            ref = frame.activeSpells[i-1]
            paddingX = paddingX * 2
        end
        icon:ClearAllPoints()
        if side == "LEFT" then
            icon:SetPoint(point1, ref, point2, -1 * paddingX, paddingY)
        else
            icon:SetPoint(point2, ref, point1, paddingX, paddingY)
        end
        if E.db.BONK.CD.Enabled == true then
            icon:Show()
        else
            icon:Hide()
        end
    end
end

------
-- BONK:Party_ShowDRFrame
------
function BONK:Party_ShowDRFrame(category, spellID, sourceName, sourceGUID)
    local frame = BONK:Party_FindFrame(sourceGUID)
    if not frame then return end
    local duration = 0

    local icon = nil
    if frame.dr[category] then
        icon = frame.dr[category]
    else
        icon = BONK:Party_ConstructFrameIcon(frame, "dr", category)
        frame.dr[category] = icon
    end

    if sourceName == "Test" then
        duration = 560
        icon.isTest = true
    else
        icon.isTest = false
    end

    icon:UnregisterAllEvents()

    if icon.reset <= GetTime() then
        icon.diminished = 1
    else
        icon.diminished = DRData:NextDR(icon.diminished, category)
    end
    if duration == 0 then
        icon.duration = DRData:GetResetTime()
    else
        icon.duration = duration
    end
    icon.timeLeft = icon.duration
    local now = GetTime()
    icon.reset = icon.duration + now

    local text, r, g, b = unpack(drTexts[icon.diminished])
	icon.drtext:SetText(text)
	icon.drtext:SetTextColor(r,g,b)
    icon.drtext:SetAlpha(1)
    icon.cdtext:SetAlpha(1)
	icon.texture:SetTexture(GetSpellTexture(spellID))

    icon.cooldown:SetCooldown(now, icon.duration)
    icon.cooldown:SetSwipeColor(0, 0, 0, 0.65)
    if not icon.active or icon.active == false then
        icon.active = true
        table.insert(frame.activeDRs, icon)
    end
    icon:SetScript("OnUpdate", function(icon, elapsed)
        BONK:Update_CooldownIcon(icon, elapsed)
    end)
    BONK:Spell_UpdateIcons(frame)
    BONK:DR_UpdateIcons(frame)
end

------
-- BONK:DR_UpdateIcons
------
function BONK:DR_UpdateIcons(frame)
    local remove = {}

    if not frame.activeDRs then return end
    for _,icon in pairs(frame.activeDRs) do
        if icon.active == false then
            remove[icon.category] = true
        end
    end

    for i = #frame.activeDRs, 1, -1 do
        local icon = frame.activeDRs[i]
        if (remove[icon.category]) then
            table.remove(frame.activeDRs, i)
        end
    end

    for i = 1, #frame.activeDRs, 1 do
        local icon = frame.activeDRs[i]
        local paddingX = E.db.BONK.DR.PaddingX
        local paddingY = 0
        local point1 = "TOPRIGHT"
        local point2 = "TOPLEFT"

        local side = E.db.BONK.DR.Position
        local ref = frame
        if i == 1 then
            if frame.trinket and side == E.db.BONK.Trinket.Position then
                ref = frame.trinket
            end

            if  side == E.db.BONK.CD.Position then
                if E.db.BONK.General.Stack == true then
                    local op = -1
                    if E.db.BONK.General.Order == "CD" then
                        op = 1
                        point1 = "BOTTOMRIGHT"
                        point2 = "BOTTOMLEFT"
                    end
                    local heightDiff = (frame:GetHeight()/2) - icon:GetHeight()
                    paddingY = op * (heightDiff - E.db.BONK.General.SeparatorY)
                elseif E.db.BONK.General.Order == "CD" and #frame.activeSpells > 0 then
                    ref = frame.activeSpells[#frame.activeSpells]
                    paddingX = paddingX + E.db.BONK.CD.PaddingX
                end
            end
            paddingX = paddingX + E.db.BONK.DR.SeparatorX
        else
            ref = frame.activeDRs[i-1]
            paddingX = paddingX * 2
        end
        icon:ClearAllPoints()
        if side == "LEFT" then
            icon:SetPoint(point1, ref, point2, -1 * paddingX, paddingY)
        else
            icon:SetPoint(point2, ref, point1, paddingX, paddingY)
        end

        if E.db.BONK.DR.Enabled == true then
            icon:Show()
        else
            icon:Hide()
        end
    end
end

------
-- BONK:Update_CooldownIcon
------
function BONK:Update_CooldownIcon(icon, elapsed)
    if GetTime() < icon.reset and icon.timeLeft > 0 and icon.active == true then
        icon.timeLeft = icon.timeLeft - elapsed
        BONK:SetFormattedNumber(icon.cdtext, icon.timeLeft)
    end
end

------
-- BONK:SetFormattedNumber
------
function BONK:SetFormattedNumber(frame, number)
	local minutes = floor(number / 60)
	if minutes > 0 then
		local seconds = number - minutes * 60
        local r = 1; local g = 1; local b = 1;
		frame:SetTextColor(r, g, b)
		frame:SetText(string.format("%sm %.0f", minutes, seconds))
	else
		if number > 5 then
            local r = 1; local g = 0.65; local b = 0;
			frame:SetTextColor(r, g, b)
			frame:SetText(string.format("%.0f", number))
		else
            local r = 1; local g = 0; local b = 0;
			frame:SetTextColor(r, g, b)
			if number == 0 then
				frame:SetText("")
			else
				frame:SetText(string.format("%.1f", number))
			end
		end
	end
end

------
-- BONK:Reset_CooldownIcon
------
function BONK:Reset_CooldownIcon(icon, hideTrinket)
    icon.active = false
    icon:UnregisterAllEvents()

    if not icon.isTrinket or icon.isTrinket == false or hideTrinket == true then
        icon:Hide()
    else
        icon.texture:SetTexture("Interface\\Icons\\INV_Jewelry_Necklace_37")
    end

    icon.cdtext:SetAlpha(0)
    if icon.drtext then
        icon.drtext:SetAlpha(0)
        icon.diminished = 0
    end
    icon.reset = 0
    icon.timeLeft = 0
end

------
-- BONK:Party_FindFrame
------
function BONK:Party_FindFrame(sourceGUID)
    local groupSize = max(min(GetNumGroupMembers(), 5), 1)

    for i=1,groupSize,1 do
        local f = UF.headers.party.groups[1][i]
        if f and f.unit and (f.unit:match("party%d?$") or f.unit == "player") and UnitGUID(f.unit) == sourceGUID then
            return f
        end
    end
    return nil
end

------
-- BONK:Update_PositionSettings
------
function BONK:Update_PositionSettings()
    local groupSize = max(min(GetNumGroupMembers(), 5), 1)

    for i = 1, groupSize, 1 do
        local frame = UF.headers.party.groups[1][i]
        if frame and frame.trinket then
            frame.trinket:ClearAllPoints()
            if E.db.BONK.Trinket.Position == "LEFT" then
                frame.trinket:SetPoint("TOPRIGHT", frame, "TOPLEFT", -1 * E.db.BONK.Trinket.SeparatorX, 0)
            else
                frame.trinket:SetPoint("TOPLEFT", frame, "TOPRIGHT", E.db.BONK.Trinket.SeparatorX, 0)
            end

            if E.db.BONK.Trinket.Enabled == true then
                frame.trinket:Show()
            else
                frame.trinket:Hide()
            end

            if E.db.BONK.Trinket.Order == "CD" then
                BONK:Spell_UpdateIcons(frame)
                BONK:DR_UpdateIcons(frame)
            else
                BONK:DR_UpdateIcons(frame)
                BONK:Spell_UpdateIcons(frame)
            end
        end
    end
end

------
-- BONK:Update_IconSettings
------
function BONK:Update_IconSettings()
    local groupSize = max(min(GetNumGroupMembers(), 5), 1)

    for i = 1, groupSize, 1 do
        local frame = UF.headers.party.groups[1][i]
        if frame and frame.trinket then
            frame.trinket.cdtext:SetFont(E["media"].normFont, E.db.BONK.Trinket.TimerFontSize, "OUTLINE")

            BONK:Update_IconPoints(frame, frame.trinket, E.db.BONK.Trinket.IconSize)
        end

        for _, icon in pairs(frame.activeSpells) do
            icon.cdtext:SetFont(E["media"].normFont, E.db.BONK.CD.TimerFontSize, "OUTLINE")

            BONK:Update_IconPoints(frame, icon, E.db.BONK.CD.IconSize)
        end

        for _, icon in pairs(frame.activeDRs) do
            icon.cdtext:SetFont(E["media"].normFont, E.db.BONK.DR.TimerFontSize, "OUTLINE")
            icon.drtext:SetFont(E["media"].normFont, E.db.BONK.DR.DRFontSize, "OUTLINE")

            BONK:Update_IconPoints(frame, icon, E.db.BONK.DR.IconSize)
        end
    end
end

------
-- BONK:Update_IconPoints
------
function BONK:Update_IconPoints(frame, icon, size)
    icon:SetWidth(frame:GetHeight()*size)
    icon:SetHeight(frame:GetHeight()*size)

    icon.cooldown:SetAllPoints(icon)
    icon.texture:SetAllPoints(icon)
end

------
-- BONK:Update_UnitSpec
------
function BONK:Update_UnitSpec(frame)
    if frame.unit == "player" then
        frame.specID = GetSpecialization()
    else
        frame.specID = GetInspectSpecialization(frame.unit)
    end
end

------
-- BONK:Group_Roster_Update
------
function BONK:Group_Roster_Update()
    local groupSize = max(min(GetNumGroupMembers(), 5), 1)

    for i = 1, groupSize, 1 do
        local f = UF.headers.party.groups[1][i]
        if f and f.unit then
            if not UnitGUID(f.unit) then return end
            if not f.trinket then
                BONK:Party_ConstructFrame(f)
                BONK:Update_UnitSpec(f)
            end
        end
    end
end

------
-- BONK:Show_TestIcons
------
function BONK:Show_TestIcons()
    local groupSize = max(min(GetNumGroupMembers(), 5), 1)

    for i = 1, groupSize, 1 do
        local f = UF.headers.party.groups[1][i]
        if f and f.unit then
            if not UnitGUID(f.unit) then return end
            if f.trinket then
                local guid = UnitGUID(f.unit)
                BONK:Party_ShowSpellFrame(208683, "Test", guid)
                BONK:Party_ShowSpellFrame(136, "Test", guid)
                BONK:Party_ShowSpellFrame(79140, "Test", guid)
                BONK:Party_ShowDRFrame("disorient", 33786, "Test", guid)
                BONK:Party_ShowDRFrame("incapacitate", 3355, "Test", guid)
            end
        end
    end
end

------
-- BONK:Hide_TestIcons
------
function BONK:Hide_TestIcons()
    local groupSize = max(min(GetNumGroupMembers(), 5), 1)

    for i = 1, groupSize, 1 do
        local f = UF.headers.party.groups[1][i]
        if f and f.unit then
            if not UnitGUID(f.unit) then return end
            if f.trinket then
                if (f.trinket.isTest == true) then
                    BONK:Reset_CooldownIcon(f.trinket)
                    f.trinket.isTest = false
                end

                for _, icon in pairs(f.activeSpells) do
                    if icon.isTest and icon.isTest == true then
                        BONK:Reset_CooldownIcon(icon)
                        icon.isTest = false
                    end
                end

                for _, icon in pairs(f.activeDRs) do
                    if icon.isTest and icon.isTest == true then
                        BONK:Reset_CooldownIcon(icon)
                        icon.isTest = false
                    end
                end
                BONK:Spell_UpdateIcons(f)
                BONK:DR_UpdateIcons(f)
            end
        end
    end
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
