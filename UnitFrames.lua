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
    BONK:Print("Assigning", self.GUID)

    if not self.hostile then
        if self:TypeEnabled("trinket") then
            local trinket = BONK.NewIconFrame(208683, self, self.db.Trinket.IconSize, self.db.Trinket.TimerFontSize, nil, true)
            trinket:SetTextureOverride("Interface\\Icons\\INV_Jewelry_Necklace_37")
            self.trinket = trinket
        end

        if parent.unit == "player" then
            self.specID = GetSpecialization()
        else
            self.specID = GetInspectSpecialization(parent.unit)
        end
    else
        self.specID = GetArenaOpponentSpec(string.sub(parent.unit, 6, 6))
    end

    if self.specID then
        BONK:Print("Spec "..self.specID)
    end

    self:UpdateIcons()
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
function BUF:HandleCast(type, spellID, startTime, duration, category)
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
        if OmniBar.cooldowns[spellID] and OmniBar.cooldowns[spellID].default then
            table.insert(self.active[type], 1, icon)
        else
            table.insert(self.active[type], icon)
            if #self.active.drs then
            end
        end
    end

    icon:BeginCooldown(spellID, startTime, duration+10, category)
    self:UpdateIcons()
end

------
-- BUF:Release
------
function BUF:Release()
    BONK:Print("Releasing")
    for _,type in pairs(self:GetOrder(true)) do
        self:ReleaseIcons(type)
    end

    if self.trinket then
        self.trinket:Release(self.trinket)
    end
    self.trinket = nil
    self.GUID = nil
    self.parent = nil
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
    if self.trinket then
        self:UpdateIconPosition(self.trinket, "trinket", 0)
    end

    for _,type in pairs(self:GetOrder()) do
        self:CheckActiveIcons(type)
        for i = 1, #self.active[type], 1 do
            local icon = self.active[type][i]
            self:UpdateIconPosition(icon, type, i)
        end
    end
end

------
-- BUF:CheckActiveIcons
------
function BUF:CheckActiveIcons(type)
    local remove = {}

    for _,icon in pairs(self.active[type]) do
        if not icon:IsActive() then
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
function BUF:UpdateIconPosition(icon, type, j)
    if icon.parent ~= self.parent then
        icon:SetParent(self.parent)
    end

    local info = self:GetPositionInfo(icon, type, j)
    icon:UpdatePosition(info)
end

------
-- BUF:GetPositionInfo
--
-- A total mess, need to refactor
------
function BUF:GetPositionInfo(icon, type, j)
    local info = {}

    local ldb = nil
    local other = nil
    local otherActive = false
    local otherPaddingX = 0

    if type == "trinket" then
        ldb = self.db.Trinket
    elseif type == "spells" then
        ldb = self.db.CD
        other = "drs"
        otherActive = #self.active.drs > 0
        otherPaddingX = self.db.DR.PaddingX
    elseif type == "drs" then
        ldb = self.db.DR
        other = "spells"
        otherActive = #self.active.spells > 0
        otherPaddingX = self.db.CD.PaddingX
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
            if ldb.Position == self.db.Trinket.Position and self.trinket then
                info.anchor = self.trinket.icon
            end
            if self.db.CD.Position == self.db.DR.Position then
                if type ~= self.db.General.Order and otherActive == true then
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
    BONK:Print("Unknown type "..type)
end
