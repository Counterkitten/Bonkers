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
    local self = setmetatable({}, BIF)
    self.iconID = iconID
    self.unitFrame = unitFrame
    self.db = unitFrame.db
    self.parent = unitFrame.parent
    self.size = size
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

    icon:ClearAllPoints()
    icon:SetNormalTexture(nil)
    icon.texture = self:CreateTexture(icon)
    icon.cooldown = self:CreateCooldown(icon)

    icon.auraFrame = CreateFrame("Frame", nil, icon)
    icon.auraFrame.borderWidth = 4
    local bw = icon.auraFrame.borderWidth
    icon.auraFrame:SetPoint("TOPLEFT", icon, "TOPLEFT", bw, -bw)
    icon.auraFrame:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -bw, bw)
    icon.auraFrame:SetFrameLevel(icon:GetFrameLevel()+2)
    icon.auraFrame.texture = self:CreateTexture(icon.auraFrame)
    icon.auraFrame:Hide()
    icon.auraMark = self:CreateCooldown(icon, nil, true)
    icon.auraMark:Hide()

    icon.cooldownMark = self:CreateCooldown(icon, true)
    icon.cooldownMark.max = 0

    icon.cdtext = self:CreateText(icon, self.fontSize)

    if self.hasDR then
        icon.drtext =  self:CreateText(icon, self.drFontSize, true)
        icon.diminished = 0
    end

    icon.reset = 0
    icon.timeLeft = 0
    icon.showing = nil

    self.icon = icon
    self:SetSize(self.size)
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
function BIF:BeginCooldown(spellID, startTime, duration, category, auraInfo, forceShrink)
    if self.active then
        if startTime - self.icon.startTime < 1 then return end

        local cd = BCD.cooldowns[spellID]
        local hasCharges = cd and (cd.charges ~= nil or (cd.parent and BCD.cooldowns[cd.parent].charges ~= nil))
        if not hasCharges and not self.icon.drtext and not self.textureOverride then
            self:UpdateCooldownMark(self.icon.timeLeft, self.icon.duration)
        end
    end
    self.icon:UnregisterAllEvents()

    self.active = true
    self.icon.auraInfo = auraInfo
    self.icon.startTime = startTime
    self.icon.duration = duration
    self.icon.timeLeft = duration

    self.icon.forceShrink = forceShrink

    if auraInfo and (not self.icon.drtext and not self.textureOverride) then
        if auraInfo.canSteal then
            self.icon.auraMark:SetSwipeColor(0, 0, 1, 1)
        else
            self.icon.auraMark:SetSwipeColor(1, 0, 0, 1)
        end
        self.icon.auraMark:SetCooldown(auraInfo.expires - auraInfo.duration, auraInfo.duration)
        self.icon.auraMark:Show()
        self.icon.auraFrame:Show()
    end

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
-- BIF:ShouldShrink
------
function BIF:ShouldShrink()
    if self.db.Shrink.Enabled then
        local timeLeft = self.icon.timeLeft
        local duration = self.icon.duration
        if self.icon.forceShrink then
            return true
        elseif (not self.icon.auraInfo or not self.db.Shrink.Aura) and timeLeft > self.db.Shrink.Reset and duration - timeLeft > self.db.Shrink.Initial then
            if self.icon.cooldownMark.max and self.icon.timeLeft - self.icon.cooldownMark.max > self.db.Shrink.Initial then
                return true
            end
        end
    end
    return nil
end

------
-- BIF:Show
------
function BIF:Show()
    if not self:IsShowing() and self:ShouldShow() and self:IsEnabled() then
        self.icon:Show()
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
    if force or not self:IsEnabled() or (self:IsShowing() and not self:ShouldShow()) then
        self.icon:Hide()
        self.icon.auraInfo = nil
        self.icon:ClearAllPoints()
        self.showing = nil
    end
end

------
-- BIF:HideAura
------
function BIF:HideAura()
    self.icon.auraInfo = nil
    self.icon.auraMark:Hide()
    self.icon.auraFrame:Hide()
    self.unitFrame:UpdateIcons()
end


------
-- BIF:AuraEnded
------
function BIF:AuraEnded()
    self:HideAura()
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
    local shouldShrink = self:ShouldShrink()
    if info.shrunk and not self.icon.shrunk then
        self:SetSize(nil, info.shrunk)
    elseif not info.shrunk and self.icon.shrunk then
        self:SetSize()
    end

    if info.anchor and info.anchor ~= self.icon then
        self.icon:ClearAllPoints()
        self.icon:SetPoint(info.prefix1..info.suffix1, info.anchor, info.prefix2..info.suffix2, info.paddingX, info.paddingY)
    end

    self:Show()
end

------
-- BIF:UpdateIconSize
------
function BIF:UpdateSettings(size, fontSize, drFontSize)
    self:SetSize(size)
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
function BIF:SetSize(size, shrink)
    if size then
        self.size = size
    end

    if self.icon and self.size then
        local height = self.parent:GetHeight() * self.size
        local fontSize = self.fontSize
        if shrink then
            height = self.parent:GetHeight() * self.db.Shrink.IconSize
            fontSize = self.db.Shrink.TimerFontSize
            self.icon.shrunk = true
        else
            self.icon.shrunk = nil
        end
        self.icon:SetWidth(height)
        self.icon:SetHeight(height)
        self.icon.cdtext:SetFont(E["media"].normFont, fontSize, "OUTLINE")
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
        if self.icon.auraFrame then
            self.icon.auraFrame.texture:SetTexture(texture)

            local bw = self.icon.auraFrame.borderWidth
            local d = bw / self.icon:GetHeight()

            local left, right, top, bottom = 0, 1, 0, 1
            left = left + (right - left) * d
            right = right - (right - left) * d
            top = top + (bottom - top) * d
            bottom = bottom - (bottom - top) * d

            self.icon.auraFrame.texture:SetTexCoord(left, right, top, bottom)
        end
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
    self.unitFrame:UpdateIcons()
end

------
-- BIF:CreateCooldown
------
function BIF:CreateCooldown(icon, isMark, isBorder)
    local cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    if isMark then
        cooldown:SetSwipeColor(1, 0, 0, 0.3)
        cooldown:SetSwipeTexture("Interface\\ChatFrame\\ChatFrameBackground")
        cooldown:SetFrameLevel(icon:GetFrameLevel()+3)
    elseif isBorder then
        cooldown:SetSwipeColor(1, 0, 0, 1)
        cooldown:SetSwipeTexture("Interface\\ChatFrame\\ChatFrameBackground")
        cooldown:SetFrameLevel(icon:GetFrameLevel()+1)
        cooldown:SetScript("OnCooldownDone", function(cd)
            self:AuraEnded(cd)
        end)
    else
        cooldown:SetSwipeColor(0, 0, 0, 0.5)
        cooldown:SetReverse(true)
        cooldown:SetScript("OnCooldownDone", function(cd)
            self:CooldownDone(cd)
        end)
        cooldown:SetAllPoints()
        cooldown:SetFrameLevel(icon:GetFrameLevel()+4)
    end

    cooldown:SetAllPoints()

    return cooldown
end

------
-- BIF:UpdateCooldown
------
function BIF:UpdateCooldown(icon, elapsed)
    if GetTime() < icon.reset and icon.timeLeft > 0 and icon.iconFrame.active == true then
        icon.timeLeft = icon.timeLeft - elapsed
        self:SetFormattedNumber(icon.cdtext, icon.timeLeft)

        if (self.icon.shrunk and not self:ShouldShrink()) or (not self.icon.shrunk and self:ShouldShrink()) then
            self.unitFrame:UpdateIcons()
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
-- BIF:CreateText
------
function BIF:CreateText(icon, fontSize, isDR)
    local text = icon.cooldown:CreateFontString(nil, "OVERLAY")
    text:SetJustifyH("CENTER")
    if (isDR) then
        text:SetPoint("BOTTOMRIGHT", icon.cooldown)
    else
        text:SetPoint("CENTER", icon.cooldown)
    end
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
            local r = 1; local g = 1; local b = 1;
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