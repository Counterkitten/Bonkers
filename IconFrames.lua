local BONK, E, L, V, P, G = unpack(select(2, ...))
local DRData = LibStub("DRData-1.0")

local GetSpellTexture = GetSpellTexture

local drTexts = {
    [1] = {"\194\189", 0, 1, 0},
    [0.5] = {"\194\188", 1, 0.65, 0},
    [0.25] = {"%", 1, 0, 0},
    [0] = {"%", 1, 0, 0},
}
local db = E.db.BONK

BIF = {}

------
-- BIF:NewIconFrame
------
function BIF:NewIconFrame(self, size, padding, fontSize)
    self:NewIconFrame(self, size, padding, fontSize, nil, false)
end
function BIF:NewIconFrame(self, size, padding, fontSize, priority)
    self:NewIconFrame(self, size, padding, fontSize, nil, priority)
end
function BIF:NewIconFrame(self, size, paddingX, fontSize, drFontSize, priority)
    self.isPriority = priority
    self.size = size
    self.paddingX = paddingX
    self.fontSize = fontSize
    self.drFontSize = drFontSize
    self.priority = priority
end

------
-- BIF:ConstructIcon
------
function BIF:ConstructIcon(self)
    local icon = CreateFrame('Button', nil, self.parent, "ActionButtonTemplate")
    icon.spacing = E.Spacing
    icon:SetFrameLevel(self.parent.RaisedElementParent:GetFrameLevel() + 10)

    icon:SetWidth(self.size)
    icon:SetHeight(self.size)

    icon:ClearAllPoints()
    icon:SetNormalTexture(nil)
    icon.texture = BIF:CreateTexture(icon)

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints(icon)
    icon.cooldown:SetReverse(true)
    icon.cooldown:SetScript("OnCooldownDone", function(cooldown)
        local i = cooldown:GetParent()
        BIF:Reset_CooldownIcon(i)
        BIF:Spell_UpdateIcons(i:GetParent())
        BIF:DR_UpdateIcons(i:GetParent())
    end)

    icon.cdtext = BIF:CreateFontString(icon, self.fontSize)

    if self.drFontSize then
        icon.drtext =  BIF:CreateFontString(icon, self.drFontSize)
        icon.diminished = 0
    else
        icon.cdtext:SetFont(E["media"].normFont, E.db.BONK.Trinket.TimerFontSize, "OUTLINE")
    end
    icon.reset = 0
    icon.timeLeft = 0

    icon.active = false
    icon:Hide()
end

------
-- BIF:Show
------
function BIF:Show(self, parent, anchor, corner, side, offsetX, offsetY)
    self.parent = parent
    self.anchor = anchor

    if not self.icon then
        self:ConstructIcon(self)

    local paddingX = self.padding + offsetX
    if anchor.paddingX then
        paddingX = paddingX + anchor.paddingX
    end

    if side == "LEFT" then
        self.icon:SetPoint(corner.."RIGHT", anchor, corner.."LEFT", -1 * paddingX, 0)
    else
        self.icon:SetPoint(corner.."LEFT", anchor, corner.."RIGHT", paddingX, 0)
    end

    self.icon:Show()
    self.icon.active = true
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



    return icon
end

------
-- BIF:SetSize
------
function BIF:SetSize(self, size)
    self.size = size
    if self.icon then
        icon:SetWidth(size)
        icon:SetHeight(size)
    end
end

------
-- BIF:SetTexture
------
function BIF:SetTexture(self, spellID)
    local _, _, texture = GetSpellInfo(spellID)

    self.texture = texture

    if self.icon then
        self.icon.texture:SetTexture(texture)
    end
end

------
-- BIF:SetTextureString
------
function BIF:SetTextureString(self, string)
    self.texture = string

    if self.icon then
        self.icon.texture:SetTexture(string)
    end
end

---- Static Functions ----

------
-- BIF:CreateFontString
------
function BIF:CreateFontString(icon, fontSize)
    local text = icon.cooldown:CreateFontString(nil, "OVERLAY")
    text:SetJustifyH("CENTER")
    text:SetPoint("CENTER", icon.cooldown)
    text:SetAlpha(0)
    text:SetFont(E["media"].normFont, fontSize, "OUTLINE")

    return text
end

------
-- BIF:CreateTexture
------
function BIF:CreateTexture(icon)
    local texture = icon:CreateTexture()
    texture:SetAllPoints(icon)
    texture:SetHeight(icon:GetHeight())
    texture:SetWidth(icon:GetWidth())

    return texture
end