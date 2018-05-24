local BONK, E, L, V, P, G = unpack(select(2, ...))
local UF = E:GetModule("UnitFrames")

local _G = _G
local CreateFrame = CreateFrame
local GetInspectSpecialization = GetInspectSpecialization
local GetNumGroupMembers = GetNumGroupMembers
local GetSpecialization = GetSpecialization
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime

local BUF = {}
BUF.__index = BUF

------
-- BONK:NewFrame
------
function BONK.NewFrame(hostile)
    local self = setmetatable({}, BUF)

    if hostile then
        self.db = E.db.BONK.Arena
    else
        self.db = E.db.BONK.Party
    end

    self.hostile = hostile
    self.parent = nil
    self.GUID = nil
    self.spells = {}
    self.drs = {}
    self.active = {}
    self.active.spells = {}
    self.active.drs = {}

    return self
end

------
-- BUF:AssignFrame
------
function BUF:AssignFrame(parent, GUID)
    self.parent = parent
    self.GUID = GUID
    BONK:Print("Assigning", self.parent.unit, self.GUID)

    if not self.hostile then
        if self:TypeEnabled("trinket") then
            local trinket = BONK.NewIconFrame(208683, self, self.db.Trinket.IconSize, self.db.Trinket.TimerFontSize, nil, true)
            trinket:SetTextureOverride("Interface\\Icons\\INV_Jewelry_Necklace_37")
            self.trinket = trinket
        end

        if self.parent.unit == "player" or UnitGUID(self.parent.unit) == UnitGUID("player") then
            local spec = GetSpecialization()
            self.specID = GetSpecializationInfo(spec)
            BONK:Print(self.specID)
        else
            self.specID = 1
        end
    else
        self.specID = GetArenaOpponentSpec(string.sub(self.parent.unit, 6, 6))
        BONK:Print(self.specID)
    end

    self.border = self:CreateBorder()
    self:UpdateIcons()
end

------
-- BUF:CreateBorder
------
function BUF:CreateBorder()
    local border = CreateFrame("Frame", nil, self.parent)

    border:SetBackdrop({
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
      edgeSize = 2,
      bgFile = nil,
      insets = {
        left = 1,
        right = 1,
        top = 1,
        bottom = 1,
      },
    });
    border:SetAllPoints(self.parent)
    border:SetPoint("BOTTOMLEFT", self.parent, "BOTTOMLEFT", -1, -1);
    border:SetPoint("TOPRIGHT", self.parent, "TOPRIGHT", 1, 1);
    border:SetBackdropBorderColor(1, 0, 0, 1);
    border:SetBackdropColor(0, 0, 0, 0);
    border:SetFrameLevel(self.parent:GetFrameLevel()+10)
    border:Hide()

    return border
end

------
-- BUF:UpdateParent
------

function BUF:GetBattleFieldIndexFromUnitName(name)
	local nameFromIndex
	for index = 1, GetNumBattlefieldScores() do
		nameFromIndex = GetBattlefieldScore(index)
		if nameFromIndex == name then
			return index
		end
	end
	return nil
end

------
-- BUF:UpdateParent
------
function BUF:UpdateParent(parent)
    self.parent = parent
    self:UpdateIcons()
end

------
-- BUF:MakeNewIcon
------
function BUF:MakeNewIcon(type, iconID)
    local size = self.db.CD.IconSize
    local fontSize = self.db.CD.TimerFontSize
    local drFontSize = nil

    if type == "drs" then
        size = self.db.DR.IconSize
        fontSize = self.db.DR.TimerFontSize
        drFontSize = self.db.DR.DRFontSize
    end
    local icon = BONK.NewIconFrame(iconID, self, size, fontSize, drFontSize, false)

    return icon
end

------
-- BUF:HandleCast
------
function BUF:HandleCast(type, spellID, startTime, duration, category, auraInfo, forceShrink)
    local icon = nil
    local skip = nil

    if not self:TypeEnabled(type) then return end

    if type == "trinket" then
        if not self.trinket then return end
        icon = self.trinket
        skip = true
    else
        icon = self[type][category or spellID]
        if not icon then
            icon = self:MakeNewIcon(type, category or spellID)
            self[type][category or spellID] = icon
        end
    end
    if not icon then return end

    if not skip and not icon:IsActive() then
        if BCD.cooldowns[spellID] and BCD.cooldowns[spellID].default then
            table.insert(self.active[type], 1, icon)
        else
            table.insert(self.active[type], icon)
            if #self.active.drs then
            end
        end
    end

    icon:BeginCooldown(spellID, startTime, duration, category, auraInfo, forceShrink)
    self:UpdateIcons()
end

------
-- BUF:HideAura
------
function BUF:HideAura(spellID)
    if self.spells[spellID] then
        self.spells[spellID]:HideAura()
    end
end

------
-- BUF:Release
------
function BUF:Release()
    for _,type in pairs(self:GetOrder(true)) do
        self:ReleaseIcons(type)
    end

    if self.trinket then
        self.trinket:Release(self.trinket)
    end
    self.trinket = nil
    self.GUID = nil
    self.parent = nil
    if self.border then
        self.border:Hide()
        self.border = nil
    end
end

------
-- BUF:ReleaseIcons
------
function BUF:ReleaseIcons(type)
    for i = #self.active[type], 1, -1 do
        local icon = self.active[type][i]
        icon:Release()
        self[type][icon.iconID] = nil
    end

    for _, icon in pairs(self[type]) do
        if icon then
            icon:Release()
        end
    end
    self[type] = {}
    self.active[type] = {}
end

------
-- BUF:UpdateIcons
------
function BUF:UpdateIcons()
    self.shrunk = {}
    self.normal = {}

    -- if UnitGUID(self.parent.unit) ~= self.GUID then
    --     BONK:Print("WRONG PARENT! "..self.GUID)
    -- end

    if self.trinket then
        self:UpdateIconPosition(self.trinket, "trinket", 0)
    end

    for _,type in pairs(self:GetOrder()) do
        for i = #self.active[type], 1, -1 do
            self.active[type][i].icon:ClearAllPoints()
            --self.active[type][i].icon:SetPoint("RIGHT", self.parent, "LEFT")
        end
    end

    for _,type in pairs(self:GetOrder(true)) do
        self:CheckActiveIcons(type)
        if type == "drs" or #self.shrunk == 0 or not self.db.Shrink.Enabled then
            for i = 1, #self.active[type], 1 do
                local icon = self.active[type][i]
                self:UpdateIconPosition(icon, type, self.active[type], i)
            end
        else
            for i = 1, #self.shrunk, 1 do
                self:UpdateIconPosition(self.shrunk[i], type, self.shrunk, i, true)
            end
            for i = 1, #self.normal, 1 do
                self:UpdateIconPosition(self.normal[i], type, self.normal, i)
            end
        end
    end
end

------
-- BUF:CheckActiveIcons
------
function BUF:CheckActiveIcons(type)
    local remove = {}

    for id,icon in pairs(self.active[type]) do
        if not icon:IsActive() then
            remove[icon.iconID] = true
        end

        if type == "spells" then
            if icon:ShouldShrink() then
                self.shrunk[#self.shrunk+1] = icon
            else
                self.normal[#self.normal+1] = icon
            end
        end
    end

    for i = #self.active[type], 1, -1 do
        if (remove[self.active[type][i].iconID]) then
            table.remove(self.active[type], i)
        end
    end
end

------
-- BUF:UpdateIconPosition
------
function BUF:UpdateIconPosition(icon, type, active, j, shrunk)
    if not icon then return end
    if icon.parent ~= self.parent then
        icon:SetParent(self.parent)
        self.border:SetParent(self.parent)
    end

    local info = self:GetPositionInfo(icon, type, active, j, shrunk)
    icon:UpdatePosition(info, icon:ShouldShrink())
end

------
-- BUF:GetPositionInfo
--
-- A total mess, need to refactor
------
function BUF:GetPositionInfo(icon, type, active, j, shrunk)
    local info = {}

    local ldb = nil
    local other = nil
    local otherActive = false
    local otherAnchor = nil
    local otherPaddingX = 0
    local otherPaddingY = 0
    local shouldShrink = nil

    if type == "trinket" then
        ldb = self.db.Trinket
    elseif type == "spells" then
        ldb = self.db.CD
        other = "drs"
        otherActive = #self.active.drs > 0
        if otherActive then
            otherAnchor = self.active[other][#self.active[other]].icon
        end
        otherPaddingX = self.db.DR.PaddingX
        info.canShrink = self.db.Shrink.Enabled
        info.shrunk = shrunk
    elseif type == "drs" then
        ldb = self.db.DR
        other = "spells"
        otherActive = #self.active.spells > 0
        if otherActive then
            if #self.shrunk > 0 then
                if #self.normal > 0 and (not self.db.Shrink.Detach or self.db.Shrink.Position == self.db.CD.Position or self.db.CD.Position == ldb.Position) then
                    otherAnchor = self.normal[#self.normal].icon
                else
                    if #self.shrunk % 2 == 1 then
                        otherAnchor = self.shrunk[#self.shrunk].icon
                    else
                        otherAnchor = self.shrunk[#self.shrunk-1].icon
                    end
                    otherPaddingY = (self.parent:GetHeight()-(otherAnchor:GetHeight()*2))/2
                    otherPaddingY = otherPaddingY - (self.parent:GetHeight()-icon.icon:GetHeight())/2
                end
            else
                otherAnchor = self.active[other][#self.active[other]].icon
            end
        end
        otherPaddingX = self.db.CD.PaddingX
    else
        return
    end

    info.anchor = self.parent
    info.prefix1 = ""
    info.prefix2 = ""
    info.suffix1 = "RIGHT"
    info.suffix2 = "LEFT"
    info.enabled = ldb.Enabled
    info.paddingX = ldb.PaddingX or 0
    info.paddingY = 0
    info.position = ldb.Position
    if shrunk and self.db.Shrink.Detach then
        info.position = self.db.Shrink.Position
    end

    if shrunk and self.db.Shrink.Detach and self.db.Shrink.Position ~= "LEFT" and self.db.Shrink.Position ~= "RIGHT" then
        info.detached = true
        if info.position:find("LEFT") then
            info.suffix1 = "LEFT"
            info.suffix2 = "RIGHT"
        else
            info.paddingX = info.paddingX * -1
        end
        if j == 1 or j % self.db.Shrink.PerRow == 1 or self.db.Shrink.PerRow == 1 then
            if info.position:find("TOP") then
                info.prefix1 = "BOTTOM"
                info.prefix2 = "TOP"
            else
                info.prefix1 = "TOP"
                info.prefix2 = "BOTTOM"
            end

            info.suffix2 = info.suffix1

            if j ~= 1 then
                info.anchor = active[j-self.db.Shrink.PerRow].icon
            end
        else
            info.anchor = active[j-1].icon
        end
    elseif other then
        if j == 1 then
            local separator = ldb.SeparatorX
            if info.position == self.db.Trinket.Position and self.trinket then
                info.anchor = self.trinket.icon
            elseif self.parent.db.pvpTrinket and self.parent.db.pvpTrinket.enable then
                if info.position == self.parent.db.pvpTrinket.position and self.parent.Trinket then
                    info.anchor = self.parent.Trinket
                end
            end
            if not shrunk and info.canShrink and #self.shrunk > 0 and (not self.db.Shrink.Detach or self.db.Shrink.Position == ldb.Position) then
                if #self.shrunk % 2 == 1 then
                    info.anchor = self.shrunk[#self.shrunk].icon
                else
                    info.anchor = self.shrunk[#self.shrunk-1].icon
                end
                info.paddingX = info.paddingX * 2
                info.paddingY = (self.parent:GetHeight()-(info.anchor:GetHeight()*2))/2
                info.paddingY = info.paddingY - (self.parent:GetHeight()-icon.icon:GetHeight())/2
                separator = 0
            elseif self.db.CD.Position == self.db.DR.Position or (self.db.Shrink.Detach and self.db.Shrink.Position == self.db.DR.Position) then
                if type ~= self.db.General.Order and otherActive == true then
                    info.anchor = otherAnchor
                    info.paddingY = otherPaddingY
                end
            end

            info.paddingX = info.paddingX + separator
            if shrunk then
                info.prefix1 = "BOTTOM"
            end
        else
            if shrunk then
                if j % 2 == 1 then
                    info.anchor = active[j-2].icon
                    info.paddingX = info.paddingX
                else
                    info.anchor = active[j-1].icon
                    info.prefix1 = "TOP"
                    info.prefix2 = "BOTTOM"
                    info.suffix1 = ""
                    info.suffix2 = ""
                    info.paddingX = 0
                end
            else
                info.anchor = active[j-1].icon
                info.paddingX = info.paddingX * 2
            end
        end

        if not shrunk and info.anchor.shrunk then
            info.prefix1 = "TOP"
            info.prefix2 = info.prefix1
        end

        if info.position == "LEFT" then
            info.paddingX = info.paddingX * -1
        else
            local s1 = info.suffix1
            info.suffix1 = info.suffix2
            info.suffix2 = s1
        end

    end

    return info
end

------
-- BUF:RefreshSettings
------
function BUF:RefreshSettings()
    if self.trinket then
        self.trinket:UpdateSettings(self.db.Trinket.IconSize, self.db.Trinket.TimerFontSize)
    end

    for _,icon in pairs(self.spells) do
        icon:UpdateSettings(self.db.CD.IconSize, self.db.CD.TimerFontSize)
    end

    for _,icon in pairs(self.drs) do
        icon:UpdateSettings(self.db.DR.IconSize, self.db.DR.TimerFontSize, self.db.DR.DRFontSize)
    end

    self:UpdateIcons()
end

------
-- BUF:GetOrder
------
function BUF:GetOrder(reverse)
    local order = {}
    if (self.db.General.Order == "spells" and reverse ~= true) or (self.db.General.Order == "drs" and reverse == true) then
        order[0] = "spells"
        order[1] = "drs"
    else
        order[0] = "drs"
        order[1] = "spells"
    end
    return order
end

------
-- BUF:GetUnitName
------
function BUF:GetUnitName()
    return self.parent.unit
end

------
-- BUF:IsAssigned
------
function BUF:IsAssigned()
    if self.parent and self.GUID then
        return true
    end
    return nil
end

------
-- BUF:TypeEnabled
------
function BUF:TypeEnabled(type)
    if type == "trinket" then
        return self.db.Trinket.Enabled
    elseif type == "spells" then
        return self.db.CD.Enabled
    elseif type == "drs" then
        return self.db.DR.Enabled
    end
end
