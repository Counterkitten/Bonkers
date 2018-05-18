local BONK, E, L, V, P, G = unpack(select(2, ...))
local DRData = LibStub("DRData-1.0")
local SharedMedia = LibStub("LibSharedMedia-3.0");

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
function BONK.NewIconFrame(iconID, unitFrame, size, fontSize, drFontSize, priority)
    BONK:Print("New Icon Frame")
    local self = setmetatable({}, BIF)
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

    self:ConstructIcon(iconID)
    return self
end

------
-- BIF:ConstructIcon
------
function BIF:ConstructIcon(iconID)
    local icon = CreateFrame('Button', self.parent:GetName()..iconID, self.parent, "UIPanelButtonTemplate")
    icon.iconFrame = self

    icon.spacing = E.Spacing
    icon:SetFrameLevel(self.parent.RaisedElementParent:GetFrameLevel() + 10)
    icon:SetWidth(self.size)
    icon:SetHeight(self.size)

    icon:ClearAllPoints()
    icon:SetNormalTexture(nil)
    icon.texture = self:CreateTexture(icon)
    icon.cooldown = self:CreateCooldown(icon)
    icon.cooldownMark = self:CreateCooldown(icon, true)
    icon.cooldownMark.max = 0
    icon.border = self:CreateBorder(icon)

    icon.cdtext = self:CreateText(icon, self.fontSize)

    if self.drFontSize then
        icon.drtext =  self:CreateText(icon, self.drFontSize)
        icon.diminished = 0
    end

    icon.reset = 0
    icon.timeLeft = 0
    icon.showing = nil

    self.icon = icon
end

------
-- BIF:SetParent
------
function BIF:SetParent(parent)
    self.parent = parent
    self.icon:SetParent(parent)
end

------
-- BIF:BeginCooldown
------
function BIF:BeginCooldown(spellID, startTime, duration, category)
    if self.active then
        if startTime - self.icon.startTime < 1 then return end

        if not self.icon.drtext then
            self:UpdateCooldownMark(self.icon.timeLeft, self.icon.duration)
        end
    end
    self.icon:UnregisterAllEvents()

    self.active = true
    self.icon.startTime = startTime
    self.icon.duration = duration
    self.icon.timeLeft = duration;

    self.icon.border.alpha = 1

    self.icon.cdtext:SetAlpha(1)
    if self.icon.drtext then
        if not self.icon.reset or self.icon.reset <= startTime then
            self.icon.diminished = 1
        else
            self.icon.diminished = DRData:NextDR(self.icon.diminished, category)
        end
        local text, r, g, b = unpack(drTexts[self.icon.diminished])
        self.icon.drtext:SetText(text)
        self.icon.drtext:SetTextColor(r,g,b)
        self.icon.drtext:SetAlpha(1)
    end

    if not self.textureOverride then
        self:SetTexture(spellID)
    end

    self.icon.reset = startTime + duration
    self.icon.cooldown:SetCooldown(startTime, duration)
    self.icon:SetScript("OnUpdate", function(icon, elapsed)
        self:UpdateCooldown(icon, elapsed)
    end)

end

------
-- BIF:Show
------
function BIF:Show()
    if not self:IsShowing() and self:ShouldShow() and self:IsEnabled() then
        self.icon:Show()
        self.icon.border:Show()
        self.icon.cdtext:SetAlpha(1)
        if self.icon.drtext then
            self.icon.drtext:SetAlpha(1)
        end
        self.showing = true
    end
end

------
-- BIF:Hide
------
function BIF:Hide(force)
    if force or (self:IsShowing() and not self:ShouldShow()) then
        self.icon:Hide()
        self.icon.border:Hide()
        self.icon:ClearAllPoints()
        self.showing = nil
    end
end

------
-- BIF:Reset
------
function BIF:Reset(force)
    self.active = nil

    self.icon:UnregisterAllEvents()
    self:Hide(force)

    self.icon.cdtext:SetAlpha(0)
    if self.icon.drtext then
        self.icon.drtext:SetAlpha(0)
        self.icon.diminished = 0
    end
    self.icon.reset = 0
    self.icon.timeLeft = 0
    self.icon.showingBorder = false
    self.icon.border:SetBackdropBorderColor(1, 0, 0, 0)
end

------
-- BIF:Release
------
function BIF:Release()
    self:Reset(true)
    self.icon.cooldown:UnregisterAllEvents()
    self.icon.cooldown = nil
    self.icon.cooldownMark = nil

    self.icon.texture = nil
    self.icon.cdtext = nil
    self.icon.drtext = nil
end

------
-- BIF:UpdatePosition
------
function BIF:UpdatePosition(info)
    self.enabled = info.enabled

    if info.anchor and info.anchor ~= self.icon then
        self.icon:ClearAllPoints()
        if info.position == "LEFT" then
            self.icon:SetPoint(info.prefix.."RIGHT", info.anchor, info.prefix.."LEFT", -1 * info.paddingX, info.paddingY)
        else
            self.icon:SetPoint(info.prefix.."LEFT", info.anchor, info.prefix.."RIGHT", info.paddingX, info.paddingY)
        end
    end

    self:Show()
end

------
-- BIF:UpdateIconSize
------
function BIF:UpdateIconSettings(size, fontSize, drFontSize)
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
function BIF:SetSize(size)
    self.size = size
    if self.icon then
        icon:SetWidth(size)
        icon:SetHeight(size)
    end
end

------
-- BIF:SetTexture
------
function BIF:SetTexture(spellID)
    local _, _, texture = GetSpellInfo(spellID)

    self.texture = texture

    if self.icon then
        self.icon.texture:SetTexture(texture)
    end
end

------
-- BIF:SetTextureString
------
function BIF:SetTextureOverride(string)
    self.texture = string

    if self.icon then
        self.icon.texture:SetTexture(string)
        self.textureOverride = true
    end
end

------
-- BIF:IsEnabled
------
function BIF:IsEnabled()
    return self:CheckBoolean("enabled")
end

------
-- BIF:IsShowing
------
function BIF:IsShowing()
    return self:CheckBoolean("showing")
end

------
-- BIF:IsActive
------
function BIF:IsActive()
    return self:CheckBoolean("active")
end

------
-- BIF:IsPriority
------
function BIF:IsPriority()
    return self:CheckBoolean("priority")
end

------
-- BIF:CheckBoolean
------
function BIF:CheckBoolean(name)
    if self[name] and self[name] == true then
        return true
    end
    return nil
end

------
-- BIF:ShouldShow
------
function BIF:ShouldShow()
    return self:IsActive() or self:IsPriority()
end


---- Icon Functions ----

------
-- BIF:CooldownDone
------
function BIF:CooldownDone(cd)
    local self = cd:GetParent().iconFrame
    self:Reset()
    self.unitFrame:UpdateIcons(self.unitFrame)
end

------
-- BIF:CreateCooldown
------
function BIF:CreateCooldown(icon, isMark)
    local cooldown = nil
    if isMark then
        cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
        cooldown:SetSwipeColor(1, 0, 0, 0.3)
        cooldown:SetSwipeTexture("Interface\\ChatFrame\\ChatFrameBackground")
    else
        cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
        cooldown:SetSwipeColor(0, 0, 0, 0.5)
        cooldown:SetReverse(true)
    end
    cooldown:SetAllPoints()
    cooldown:SetScript("OnCooldownDone", function(cd)
        self:CooldownDone(cd)
    end)

    return cooldown
end

------
-- BIF:UpdateCooldown
------
function BIF:UpdateCooldown(icon, elapsed)
    if GetTime() < icon.reset and icon.timeLeft > 0 and icon.iconFrame.active == true then
        icon.timeLeft = icon.timeLeft - elapsed
        self:SetFormattedNumber(icon.cdtext, icon.timeLeft)

        if icon.border.alpha > 0 then
            icon.border.alpha = icon.border.alpha - 0.005
            icon.border:SetBackdropBorderColor(1, 0, 0, icon.border.alpha)
        end
    end
end

------
-- BIF:UpdateCooldownMark
------
function BIF:UpdateCooldownMark(timeLeft, duration)
    local mark = self.icon.cooldownMark

    if timeLeft > mark.max then
        mark.max = timeLeft
    end
    local div = mark.max / duration

    mark:SetCooldown(GetTime()-(1000-(div*1000)), 1000)
    mark:Show()
end

------
-- BIF:CreateBorder
------
function BIF:CreateBorder(icon)
    local border = CreateFrame("Frame", nil, icon)

    border:SetBackdrop({
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
      edgeSize = 5,
      bgFile = nil,
      insets = {
        left = 5,
        right = 5,
        top = 5,
        bottom = 5,
      },
    });
    border:SetAllPoints(icon)
    border:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", -1, -1);
    border:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 1, 1);
    border:SetBackdropBorderColor(1, 0, 0, 0);
    border:SetBackdropColor(0, 0, 0, 0);
    border:SetFrameLevel(icon:GetFrameLevel()+2)

    return border
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