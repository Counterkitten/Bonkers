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
function BONK:NewFrame(hostile)
    BONK:Print("New Unit Frame")
    local self = setmetatable({}, BUF)

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
function BUF:AssignFrame(self, parent)
    self.parent = parent
    self.GUID = UnitGUID(parent.unit)

    local trinket = BONK:NewIconFrame(208683, self, E.db.BONK.Trinket.IconSize, E.db.BONK.Trinket.TimerFontSize, nil, true)
    trinket:SetTextureOverride(trinket, "Interface\\Icons\\INV_Jewelry_Necklace_37")

    self.trinket = trinket

    if self.hostile == true then

    else
        if parent.unit == "player" then
            self.specID = GetSpecialization()
        else
            self.specID = GetInspectSpecialization(parent.unit)
        end
    end

    self:UpdateIcons(self)
end

------
-- BUF:MakeNewIcon
------
function BUF:MakeNewIcon(self, type, iconID)
    local size = E.db.BONK.CD.IconSize
    local fontSize = E.db.BONK.CD.TimerFontSize
    local drFontSize = nil

    if type == "DR" then
        size = E.db.BONK.DR.IconSize
        fontSize = E.db.BONK.DR.TimerFontSize
        drFontSize = E.db.BONK.DR.DRFontSize
    end
    icon = BONK:NewIconFrame(iconID, self, size, fontSize, drFontSize, false)

    return icon
end

------
-- BUF:HandleCast
------
function BUF:HandleCast(self, type, spellID, startTime, duration, category)
    local icon = nil
    local skip = nil

    if type == "trinket" then
        icon = self.trinket
        skip = true
    else
        icon = self[type][spellID]
        if not icon then
            icon = BUF:MakeNewIcon(self, type, category or spellID)
            self[type][category or spellID] = icon
        end
    end
    if not icon then return end

    if not skip and not icon:IsActive(icon) then
        if OmniBar.cooldowns[spellID] and OmniBar.cooldowns[spellID].default then
            table.insert(self.active[type], 1, icon)
        else
            table.insert(self.active[type], icon)
        end
    end

    icon:BeginCooldown(icon, spellID, startTime, duration, category)
    self:UpdateIcons(self)
end

------
-- BUF:Release
------
function BUF:Release(self)
    for _,type in pairs(BUF:GetOrder(true)) do
        self:ReleaseIcons(self, type)
    end

    self.trinket:Release(self.trinket)
    self.trinket = nil
    self.GUID = nil
    self.parent = nil
end

------
-- BUF:ReleaseIcons
------
function BUF:ReleaseIcons(self, type)
    for i = #self.active[type], 1, -1 do
        local icon = self.active[type][i]
        icon:Release(icon)
        self[type][icon.iconID] = nil
    end

    for _, icon in pairs(self[type]) do
        if icon then
            icon:Release(icon)
        end
    end
    self[type] = {}
    self.active[type] = {}
end

------
-- BUF:UpdateIcons
------
function BUF:UpdateIcons(self)
    self:UpdateIconPosition(self, self.trinket, "trinket", 0)
    BONK:Print("Updating")

    for _,type in pairs(self:GetOrder()) do
        self:CheckActiveIcons(self, type)
        for i = 1, #self.active[type], 1 do
            self:UpdateIconPosition(self, icon, type, i)
        end
    end
end

------
-- BUF:CheckActiveIcons
------
function BUF:CheckActiveIcons(self, type)
    local remove = {}

    for _,icon in pairs(self.active[type]) do
        if not icon:IsActive(icon) then
            remove[icon.iconID] = true
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
function BUF:UpdateIconPosition(self, icon, type, j)
    local info = BUF:GetPositionInfo(self, icon, type, j)
    icon:UpdatePosition(icon, info)
end

------
-- BUF:GetPositionInfo
--
-- A total mess, need to refactor
------
function BUF:GetPositionInfo(self, icon, type, j)
    local info = {}

    local ldb = nil
    local other = nil
    local otherActive = false
    local otherPaddingX = 0

    if type == "trinket" then
        ldb = E.db.BONK.Trinket
    elseif type == "spells" then
        ldb = E.db.BONK.CD
        other = "drs"
        otherActive = #self.active.drs > 0
        otherPaddingX = E.db.BONK.DR.PaddingX
    elseif type == "drs" then
        ldb = E.db.BONK.DR
        other = "spells"
        otherActive = #self.active.spells > 0
        otherPaddingX = E.db.BONK.CD.PaddingX
    else
        return
    end

    info.anchor = self.parent
    info.prefix = "TOP"
    info.enabled = ldb.Enabled
    info.paddingX = ldb.PaddingX or 0
    info.paddingY = 0
    info.position = ldb.Position

    if other then
        if j == 1 then
            if ldb.Position == E.db.BONK.Trinket.Position then
                info.anchor = self.trinket.icon
            end
            if E.db.BONK.CD.Position == E.db.BONK.DR.Position then
                if E.db.BONK.General.Stack == true then
                    info.stack = true
                    local op = -1
                    if type ~= E.db.BONK.General.Order then
                        op = 1
                        info.prefix = "BOTTOM"
                    end
                    local heightDiff = (self.parent:GetHeight()/2) - icon:GetHeight()
                    paddingY = op * (heightDiff - E.db.BONK.General.SeparatorY)
                elseif type ~= E.db.BONK.General.Order and otherActive == true then
                    info.anchor = self.active[other][#self.active[other]].icon
                    info.paddingX = info.paddingX + otherPaddingX
                end
            end
            info.paddingX = info.paddingX + ldb.SeparatorX
        else
            info.anchor = self.active[type][j-1].icon
            info.paddingX = info.paddingX * 2
        end
    end

    return info
end

------
-- BUF:GetOrder
------
function BUF:GetOrder(reverse)
    local order = {}
    if (E.db.BONK.General.Order == "spells" and reverse ~= true) or (E.db.BONK.General.Order == "drs" and reverse == true) then
        order[0] = "spells"
        order[1] = "drs"
    else
        order[0] = "drs"
        order[1] = "spells"
    end
    return order
end

------
-- BUF:IsAssigned
------
function BUF:IsAssigned(self)
    if self.parent and self.GUID then
        return true
    end
    return nil
end
