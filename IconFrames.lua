local BONK, E, L, V, P, G = unpack(select(2, ...))
local DRData = LibStub("DRData-1.0")

local GetSpellTexture = GetSpellTexture

local drTexts = {
    [1] = {"\194\189", 0, 1, 0},
    [0.5] = {"\194\188", 1, 0.65, 0},
    [0.25] = {"%", 1, 0, 0},
    [0] = {"%", 1, 0, 0},
}

local BIF = {}
BIF.__index = BIF

------
-- BONK:NewIconFrame
------
function BONK:NewIconFrame(iconID, unitFrame, size, fontSize, drFontSize, priority)
    BONK:Print("New Icon Frame")
    self = setmetatable({}, BIF)
    self.iconID = iconID
    self.unitFrame = unitFrame
    self.parent = unitFrame.parent
    self.size = size * self.parent:GetHeight()
    self.fontSize = fontSize
    if (drFontSize) then
        self.hasDR = true
        self.drFontSize = drFontSize
    end
    self.priority = priority

    self:ConstructIcon(self)
    return self
end

------
-- BIF:ConstructIcon
------
function BIF:ConstructIcon(self)
    local icon = CreateFrame('Button', nil, self.parent, "ActionButtonTemplate")
    icon.iconFrame = self

    icon.spacing = E.Spacing
    icon:SetFrameLevel(self.parent.RaisedElementParent:GetFrameLevel() + 10)
    icon:SetWidth(self.size)
    icon:SetHeight(self.size)

    icon:ClearAllPoints()
    icon:SetNormalTexture(nil)
    icon.texture = BIF:CreateTexture(icon)
    icon.cooldown = BIF:CreateCooldown(icon)

    icon.cdtext = BIF:CreateText(icon, self.fontSize)

    if self.drFontSize then
        icon.drtext =  BIF:CreateText(icon, self.drFontSize)
        icon.diminished = 0
    end

    icon.reset = 0
    icon.timeLeft = 0
    icon.active = nil
    icon.showing = nil

    self.icon = icon
end

------
-- BIF:BeginCooldown
------
function BIF:BeginCooldown(self, spellID, startTime, duration, category)
    self.icon:UnregisterAllEvents()

    self.active = true
    self.icon.duration = duration
    self.icon.timeLeft = duration

    self.icon.cdtext:SetAlpha(1)
    if self.icon.drtext then
        if not self.icon.reset or self.icon.reset <= startTime then
            icon.diminished = 1
        else
            icon.diminished = DRData:NextDR(icon.diminished, category)
        end
        local text, r, g, b = unpack(drTexts[self.icon.diminished])
        self.icon.drtext:SetText(text)
        self.icon.drtext:SetTextColor(r,g,b)
        self.icon.drtext:SetAlpha(1)
    end

    if not self.textureOverride then
        BIF:SetTexture(self, spellID)
    end

    self.icon.reset = startTime + duration
    self.icon.cooldown:SetCooldown(startTime, duration)
    self.icon:SetScript("OnUpdate", function(icon, elapsed)
        BIF:UpdateCooldown(icon, elapsed)
    end)

end

------
-- BIF:Show
------
function BIF:Show(self)
    if not self:IsShowing(self) and self:ShouldShow(self) and self:IsEnabled(self) then
        self.icon:Show()
        self.showing = true
    end
end

------
-- BIF:Hide
------
function BIF:Hide(self, force)
    if force or (BIF:IsShowing(self) and not BIF:ShouldShow(self)) then
        self.icon:Hide()
        self.icon:ClearAllPoints()
        self.showing = nil
    end
end

------
-- BIF:Reset
------
function BIF:Reset(self, force)
    self.active = nil

    self.icon:UnregisterAllEvents()
    BIF:Hide(self, force)

    self.icon.cdtext:SetAlpha(0)
    if self.icon.drtext then
        self.icon.drtext:SetAlpha(0)
        self.icon.diminished = 0
    end
    self.icon.reset = 0
    self.icon.timeLeft = 0
end

------
-- BIF:Release
------
function BIF:Release(self)
    BIF:Reset(self, true)
    self.icon.cooldown:UnregisterAllEvents()
    self.icon.cooldownMark:Hide()
    self.icon.cooldownMark = nil
    self.icon.cooldown = nil

    self.icon.texture = nil
    self.icon.cdtext = nil
    self.icon.drtext = nil
end

------
-- BIF:UpdatePosition
------
function BIF:UpdatePosition(self, info)
    self.enabled = info.enabled
    print(info.prefix)
    print(info.anchor)
    print(info.paddingX)

    if side == "LEFT" then
        self.icon:SetPoint(info.prefix.."RIGHT", info.anchor, info.prefix.."LEFT", -1 * info.paddingX, info.paddingY)
    else
        self.icon:SetPoint(info.prefix.."LEFT", info.anchor, info.prefix.."RIGHT", info.paddingX, info.paddingY)
    end

    BIF:Show(self)
end

------
-- BIF:UpdateIconSize
------
function BIF:UpdateIconSettings(self, size, fontSize, drFontSize)
    self.icon:SetWidth(self.parent:GetHeight()*size)
    self.icon:SetHeight(self.parent:GetHeight()*size)
    self.icon.cooldown:SetAllPoints(self.icon)
    self.icon.texture:SetAllPoints(self.icon)

    self.icon.cdtext:SetFont(E["media"].normFont, fontSize, "OUTLINE")
    if self.icon.drtext and drFontSize then
        self.icon.drtext:SetFont(E["media"].normFont, drFontSize, "OUTLINE")
    end
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
function BIF:SetTextureOverride(self, string)
    self.texture = string

    if self.icon then
        self.icon.texture:SetTexture(string)
        self.icon.textureOverride = true
    end
end

------
-- BIF:IsEnabled
------
function BIF:IsEnabled(self)
    return BIF:CheckBoolean(self, "enabled")
end

------
-- BIF:IsShowing
------
function BIF:IsShowing(self)
    return BIF:CheckBoolean(self, "showing")
end

------
-- BIF:IsActive
------
function BIF:IsActive(self)
    return BIF:CheckBoolean(self, "active")
end

------
-- BIF:IsPriority
------
function BIF:IsPriority(self)
    return BIF:CheckBoolean(self, "priority")
end

------
-- BIF:CheckBoolean
------
function BIF:CheckBoolean(self, name)
    if self[name] and self[name] == true then
        return true
    end
    return nil
end

------
-- BIF:ShouldShow
------
function BIF:ShouldShow(self)
    return BIF:IsActive(self) or BIF:IsPriority(self)
end


---- Icon Functions ----

------
-- BIF:CooldownDone
------
function BIF:CooldownDone(cd)
    local self = cd:GetParent().iconFrame
    BIF:Reset(self)
    self.unitFrame:UpdateIcons(self.unitFrame)
end

------
-- BIF:CreateCooldown
------
function BIF:CreateCooldown(self)
    local cooldown = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
    cooldown:SetAllPoints(self)
    cooldown:SetReverse(true)
    cooldown:SetSwipeColor(0, 0, 0, 0.5)
    cooldown:SetScript("OnCooldownDone", function(cd)
        BIF:CooldownDone(cd)
    end)

    cooldown.cooldownMark = CreateFrame("Cooldown", nil, cooldown)
    cooldown.cooldownMark:SetAllPoints(cooldown)
    cooldown.cooldownMark:SetReverse(true)
    cooldown.cooldownMark:SetSwipeColor(1, 0, 0, 0.5)
    cooldown.cooldownMark:Hide()

    return cooldown
end

------
-- BIF:UpdateCooldown
------
function BIF:UpdateCooldown(icon, elapsed)
    if GetTime() < icon.reset and icon.timeLeft > 0 and icon.active == true then
        icon.timeLeft = icon.timeLeft - elapsed
        BIF:SetFormattedNumber(icon.cdtext, icon.timeLeft)
    end
end

------
-- BIF:CreateText
------
function BIF:CreateText(icon, fontSize)
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

------
-- BIF:SetFormattedNumber
------
function BIF:SetFormattedNumber(text, number)
	local minutes = floor(number / 60)
	if minutes > 0 then
		local seconds = number - minutes * 60
        local r = 1; local g = 1; local b = 1;
		text:SetTextColor(r, g, b)
		text:SetText(string.format("%sm %.0f", minutes, seconds))
	else
		if number > 5 then
            local r = 1; local g = 0.65; local b = 0;
			text:SetTextColor(r, g, b)
			text:SetText(string.format("%.0f", number))
		else
            local r = 1; local g = 0; local b = 0;
			text:SetTextColor(r, g, b)
			if number == 0 then
				text:SetText("")
			else
				text:SetText(string.format("%.1f", number))
			end
		end
	end
end