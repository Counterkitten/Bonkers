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

function BONK:Party_ConstructFrameIcon(frame, type)
    return BONK:Party_ConstructFrameIcon(frame, type, nil)
end

function BONK:Party_ConstructFrameIcon(frame, type, IDorValue)
    local name = "Trinket"
    local key = "spellID"
    if type == "spell" then
        name = "Spell"..IDorValue
    elseif type == "dr" then
        name = "DR"..IDorValue
        key = "category"
    else
        key = "isTrinket"
        IDorValue = true
    end

    local icon = CreateFrame('Button', frame:GetName()..name, frame, "ActionButtonTemplate")
    icon[key] = IDorValue
    icon.spacing = E.Spacing
    icon:SetFrameLevel(frame.RaisedElementParent:GetFrameLevel() + 10)

    if key == "isTrinket" then
        icon:SetWidth(frame:GetHeight())
        icon:SetHeight(frame:GetHeight())
    else
        icon:SetWidth(frame:GetHeight())
        icon:SetHeight(frame:GetHeight())
    end

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
        BONK:Reset_CooldownIcon(cooldown:GetParent())
    end)

    icon.cdtext = icon:CreateFontString(nil, "OVERLAY")
    icon.cdtext:SetFont(E["media"].normFont, 10, "OUTLINE")
    icon.cdtext:SetJustifyH("CENTER")
    icon.cdtext:SetPoint("CENTER", icon.cooldown)
    icon.cdtext:SetAlpha(0)

    if type == "dr" then
        icon.text = icon:CreateFontString(nil, "OVERLAY")
        icon.text:SetFont(E["media"].normFont, 10, "OUTLINE")
    	icon.text:SetJustifyH("RIGHT")
    	icon.text:SetPoint("BOTTOMRIGHT", icon.cooldown, -3, 0)
        icon.text:SetAlpha(0)
        icon.diminished = 0
    end
    icon.reset = 0
    icon.timeLeft = 0

    --E:SetUpAnimGroup(icon)
    --E:RegisterCooldown(icon.cooldown)

    icon.active = false

    return icon
end

function BONK:Party_ConstructFrame(frame)
    frame.trinket = BONK:Party_ConstructFrameIcon(frame, "trinket")
    frame.trinket.texture:SetTexture("Interface\\Icons\\INV_Jewelry_Necklace_37")
    if E.db.BONK.TrinketPosition == "LEFT" then
        frame.trinket:SetPoint("TOPRIGHT", frame, "TOPLEFT")
    else
        frame.trinket:SetPoint("TOPLEFT", frame, "TOPRIGHT")
    end
    frame.trinket:Show()

    frame.spell = {}
    frame.dr = {}
    frame.activeSpells = {}
    frame.activeDRs = {}
end

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

    if normalTexture and not icon.normalTexture then
        icon.normalTexture = normalTexture
    end

    icon:UnregisterAllEvents()

    local _, _, spellTexture = GetSpellInfo(spellID)
    icon.texture:SetTexture(spellTexture)

    if duration == 0 then
        if icon.duration then
            duration = icon.duration
        else
            local cd = OmniBar.cooldowns[spellID]
            if cd.duration then
                duration = cd.duration
            elseif cd.parent then
                duration = OmniBar.cooldowns[cd.parent].duration
            end
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
    -- icon.cooldown:SetScript("OnCooldownDone", function(cooldown)
    --     BONK:Reset_CooldownIcon(cooldown:GetParent())
    -- end)
    icon.cooldown:SetCooldown(start, duration)

    icon.cdtext:SetAlpha(1)

    if not icon.active then
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
end

function BONK:Update_CooldownIcon(icon, elapsed)
    if GetTime() < icon.reset and icon.timeLeft > 0 then
        icon.timeLeft = icon.timeLeft - elapsed
        BONK:SetFormattedNumber(icon.cdtext, icon.timeLeft)
    end
end

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

function BONK:Reset_CooldownIcon(icon, hideTrinket)
    if (icon.active) then
        icon.active = false
        icon:UnregisterAllEvents()
        if not icon.isTrinket or hideTrinket == true then
            icon:Hide()
        end
        icon.cdtext:SetAlpha(0)
        if icon.text then
            icon.text:SetAlpha(0)
        end
    end
    BONK:Spell_UpdateIcons(icon:GetParent())
    BONK:DR_UpdateIcons(icon:GetParent())
end

function BONK:Spell_UpdateIcons(frame)
    local padding = 2
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
        icon.position = i

        local side = E.db.BONK.CDPosition
        local point = frame
        if icon.position == 1 then
            if frame.trinket and side == E.db.BONK.TrinketPosition then
                point = frame.trinket
            end
        else
            point = frame.activeSpells[i-1]
        end
        icon:ClearAllPoints()
        if side == "LEFT" then
            icon:SetPoint("TOPRIGHT", point, "TOPLEFT", -1 * padding, 0)
        else
            icon:SetPoint("TOPLEFT", point, "TOPRIGHT", padding, 0)
        end
        icon:Show()
    end
end

function BONK:Party_ShowDRFrame(category, spellID, sourceName, sourceGUID)
    local frame = BONK:Party_FindFrame(sourceGUID)
    if not frame then return end

    local icon = nil
    if frame.dr[category] then
        icon = frame.dr[category]
    else
        icon = BONK:Party_ConstructFrameIcon(frame, "dr", category)
        frame.dr[category] = icon
    end

    icon:UnregisterAllEvents()

    if icon.reset <= GetTime() then
        icon.diminished = 1
    else
        icon.diminished = DRData:NextDR(icon.diminished, category)
    end
    icon.duration = DRData:GetResetTime()
    icon.timeLeft = icon.duration
    local now = GetTime()
    icon.reset = icon.duration + now

    local text, r, g, b = unpack(drTexts[icon.diminished])
	icon.text:SetText(text)
	icon.text:SetTextColor(r,g,b)
    icon.text:SetAlpha(1)
    icon.cdtext:SetAlpha(1)
	icon.texture:SetTexture(GetSpellTexture(spellID))

    icon.cooldown:SetCooldown(now, icon.duration)
    icon.cooldown:SetSwipeColor(0, 0, 0, 0.65)
    if not icon.active then
        icon.active = true
        table.insert(frame.activeDRs, icon)
    end
    icon:SetScript("OnUpdate", function(icon, elapsed)
        BONK:Update_CooldownIcon(icon, elapsed)
    end)
    BONK:DR_UpdateIcons(frame)
end

function BONK:DR_UpdateIcons(frame)
    local padding = 2
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
        icon.position = i

        local side = E.db.BONK.DRPosition
        local point = frame
        if icon.position == 1 then
            if frame.trinket and side == E.db.BONK.TrinketPosition then
                point = frame.trinket
            end
        else
            point = frame.activeDRs[i-1]
        end
        icon:ClearAllPoints()
        if side == "LEFT" then
            icon:SetPoint("TOPRIGHT", point, "TOPLEFT", -1 * padding, 0)
        else
            icon:SetPoint("TOPLEFT", point, "TOPRIGHT", padding, 0)
        end

        icon:Show()
    end
end

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

function BONK:Update_Positions()
    local groupSize = max(min(GetNumGroupMembers(), 5), 1)

    for i = 1, groupSize, 1 do
        local frame = UF.headers.party.groups[1][i]
        if frame and frame.trinket then
            frame.trinket:ClearAllPoints()
            if E.db.BONK.TrinketPosition == "LEFT" then
                frame.trinket:SetPoint("TOPRIGHT", frame, "TOPLEFT")
            else
                frame.trinket:SetPoint("TOPLEFT", frame, "TOPRIGHT")
            end
            BONK:Spell_UpdateIcons(frame)
            BONK:DR_UpdateIcons(frame)
        end
    end
end

function BONK:Update_UnitSpec(frame)
    if frame.unit == "player" then
        frame.specID = GetSpecialization()
    else
        frame.specID = GetInspectSpecialization(frame.unit)
    end
end

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

function BONK:Initialize_UnitFrames()

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
