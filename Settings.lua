local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB

BSF = {}

function BSF:GetSettings()
    return {
		order = 1,
		type = "group",
		name = "|cff9482c9Bonkers|r",
        childGroups = "tab",
		args = {
            General = {
                order = 1,
                type = "group",
                name = "General",
                args = self:GeneralSettings()
            },
            Trinket = {
                order = 2,
                type = "group",
                name = "Trinket",
                args = self:GetIconSettings("Trinket")
            },
            CD = {
                order = 3,
                type = "group",
                name = "Cooldowns",
                args = self:GetIconSettings("CD")
            },
            DR = {
                order = 4,
                type = "group",
                name = "DRs",
                args = self:GetIconSettings("DR")
            },
            Shrink = {
                order = 5,
                type = "group",
                name = "Small Icons",
                args = self:GetShrinkSettings()
            },
            PSpells = {
                order = 6,
                type = "group",
                name = "Party Spells",
                args = BCD:GetSpells("Party")
            },
            ASpells = {
                order = 7,
                type = "group",
                name = "Arena Spells",
                args = BCD:GetSpells("Arena")
            }
		},
	}
end

function BSF:GeneralSettings()
    local settings = {
        TrinketEnabledP = {
            order = 3,
            type = "toggle",
            name = "Enable Party Trinket",
            get = function(info)
                return E.db.BONK.Party.Trinket.Enabled
            end,
            set = function(info, value)
                E.db.BONK.Party.Trinket.Enabled = value
                self.BONK:Update()
            end,
        },
        CDEnabledP = {
            order = 1,
            type = "toggle",
            name = "Enable Party Cooldowns",
            get = function(info)
                return E.db.BONK.Party.CD.Enabled
            end,
            set = function(info, value)
                E.db.BONK.Party.CD.Enabled = value
                self.BONK:Update()
            end,
        },
        DREnabledP = {
            order = 2,
            type = "toggle",
            name = "Enable Party DRs",
            get = function(info)
                return E.db.BONK.Party.DR.Enabled
            end,
            set = function(info, value)
                E.db.BONK.Party.DR.Enabled = value
                self.BONK:Update()
            end,
        },
        CDEnabledA = {
            order = 4,
            type = "toggle",
            name = "Enable Arena Cooldowns",
            get = function(info)
                return E.db.BONK.Arena.CD.Enabled
            end,
            set = function(info, value)
                E.db.BONK.Arena.CD.Enabled = value
                self.BONK:Update()
            end,
        },
        DREnabledA = {
            order = 5,
            type = "toggle",
            name = "Enable Arena DRs",
            get = function(info)
                return E.db.BONK.Arena.DR.Enabled
            end,
            set = function(info, value)
                E.db.BONK.Arena.DR.Enabled = value
                self.BONK:Update()
            end,
        },
        spacer10 = {
            order = 6,
            type = 'description',
            name = ''
        },
        OrderP = {
            order = 7,
            type = "select",
            name = "Party Display Order",
            values = {
                ["spells"] = "Cooldowns First",
                ["drs"] = "DRs First",
            },
            get = function(info)
                return E.db.BONK.Party.General.Order
            end,
            set = function(info, value)
                E.db.BONK.Party.General.Order = value
                self.BONK:Update()
            end,
        },
        OrderA = {
            order = 8,
            type = "select",
            name = "Arena Display Order",
            values = {
                ["spells"] = "Cooldowns First",
                ["drs"] = "DRs First",
            },
            get = function(info)
                return E.db.BONK.Arena.General.Order
            end,
            set = function(info, value)
                E.db.BONK.Arena.General.Order = value
                self.BONK:Update()
            end,
        },
        spacer0 = {
            order = 9,
            type = 'description',
            name = ''
        },
        spacer1 = {
            order = 10,
            type = 'description',
            name = ''
        },
        spacer2 = {
            order = 11,
            type = 'description',
            name = ''
        },
        spacer3 = {
            order = 12,
            type = 'description',
            name = ''
        },
        spacer4 = {
            order = 13,
            type = 'description',
            name = ''
        },
        spacer5 = {
            order = 14,
            type = 'description',
            name = ''
        },
        spacer6 = {
            order = 15,
            type = 'description',
            name = ''
        },
        spacer7 = {
            order = 16,
            type = 'description',
            name = ''
        },
        spacer8 = {
            order = 17,
            type = 'description',
            name = ''
        },
        spacer9 = {
            order = 18,
            type = 'description',
            name = ''
        },
        ShowIcons = {
            order = 19,
            type = "execute",
            name = "Display Test Icons",
            func = function()
                self.BONK.BFM:ShowTestIcons()
            end,
        },
        HideIcons = {
            order = 20,
            type = "execute",
            name = "Hide Test Icons",
            func = function()
                self.BONK.BFM:HideTestIcons()
            end,
        },
        Debug = {
            order = 21,
            type = "toggle",
            name = "Debug Mode",
            desc = "Print debug message",
            get = function(info)
                return E.db.BONK.General.Debug
            end,
            set = function(info, value)
                E.db.BONK.General.Debug = value
            end,
        },
    }

    return settings
end

function BSF:GetIconSettings(type)
    local settings = {}

    settings["Party"] = {
        order = 1,
        type = "group",
        guiInline = true,
        name = "Party Frames",
        args = self:MakeIconSettings(type, "Party")
    }

    if type ~= "Trinket" then
        settings["spacer"] = {
            order = 2,
            type = 'description',
            name = ' '
        }

        settings["Arena"] = {
            order = 3,
            type = "group",
            guiInline = true,
            name = "Arena Frames",
            args = self:MakeIconSettings(type, "Arena")
        }
    end

    return settings
end

function BSF:MakeIconSettings(type, where)
    local settings = {}
    settings["Position"] = {
        order = 1,
        type = "select",
        name = "Position",
        values = {
            ["RIGHT"] = "RIGHT",
            ["LEFT"] = "LEFT",
        },
        get = function(info)
            return E.db.BONK[where][type].Position
        end,
        set = function(info, value)
            E.db.BONK[where][type].Position = value
            self.BONK:Update()
        end,
    }
    settings["TimerFontSize"] = {
        order = 2,
        type = "range",
        name = "Timer Font Size",
        min = 0, max = 30, step = 1,
        get = function(info)
            return E.db.BONK[where][type].TimerFontSize
        end,
        set = function(info, value)
            E.db.BONK[where][type].TimerFontSize = value
            self.BONK:Update()
        end,
    }
    if type == "DR" then
        settings["DRFontSize"] = {
            order = 3,
            type = "range",
            name = "DR Font Size",
            min = 0, max = 40, step = 1,
            get = function(info)
                return E.db.BONK[where][type].DRFontSize
            end,
            set = function(info, value)
                E.db.BONK[where][type].DRFontSize = value
                self.BONK:Update()
            end,
        }
    end
    settings["spacer0"] = {
        order = 4,
        type = 'description',
        name = ''
    }
    settings["IconSize"] = {
        order = 10,
        type = "range",
        name = "Icon Size",
        min = 0.1, max = 2, step = 0.01,
        get = function(info)
            return E.db.BONK[where][type].IconSize
        end,
        set = function(info, value)
            E.db.BONK[where][type].IconSize = value
            self.BONK:Update()
        end,
    }
    settings["SeparatorX"] = {
        order = 11,
        type = "range",
        name = "Separator Width",
        min = 0, max = 100, step = 1,
        get = function(info)
            return E.db.BONK[where][type].SeparatorX
        end,
        set = function(info, value)
            E.db.BONK[where][type].SeparatorX = value
            self.BONK:Update()
        end,
    }
    if type == "DR" or type == "CD" then
        settings["PaddingX"] = {
            order = 12,
            type = "range",
            name = "Horizontal Padding",
            min = 0, max = 100, step = 1,
            get = function(info)
                return E.db.BONK[where][type].PaddingX
            end,
            set = function(info, value)
                E.db.BONK[where][type].PaddingX = value
                self.BONK:Update()
            end,
        }
    else
        settings["spacer1"] = {
            order = 13,
            type = 'description',
            name = ''
        }
    end

    return settings
end

function BSF:GetShrinkSettings()
    local settings = {}

    settings["Party"] = {
        order = 1,
        type = "group",
        guiInline = true,
        name = "Party Frames",
        args = self:MakeShrinkSettings("Party")
    }

    settings["spacer"] = {
        order = 2,
        type = 'description',
        name = ' '
    }

    settings["Arena"] = {
        order = 3,
        type = "group",
        guiInline = true,
        name = "Arena Frames",
        args = self:MakeShrinkSettings("Arena")
    }

    return settings
end

function BSF:MakeShrinkSettings(where)
    local settings = {}
    settings["ShrinkEnabled"] = {
        order = 1,
        type = "toggle",
        name = "Shrink Icons",
        get = function(info)
            return E.db.BONK[where].Shrink.Enabled
        end,
        set = function(info, value)
            E.db.BONK[where].Shrink.Enabled = value
            self.BONK:Update()
        end,
    }

    settings["WaitForEffect"] = {
        order = 2,
        type = "toggle",
        name = "Wait For Aura",
        desc = "Wait until aura ends (if it exists) before shrinking icon",
        get = function(info)
            return E.db.BONK[where].Shrink.Aura
        end,
        set = function(info, value)
            E.db.BONK[where].Shrink.Aura = value
            self.BONK:Update()
        end,
    }

    settings["IconSize"] = {
        order = 3,
        type = "range",
        name = "Icon Size",
        desc = "Size relative to unit frame height",
        min = 0.1, max = 1, step = 0.01,
        get = function(info)
            return E.db.BONK[where].Shrink.IconSize
        end,
        set = function(info, value)
            E.db.BONK[where].Shrink.IconSize = value
            self.BONK:Update()
        end,
    }

    settings["spacer0"] = {
        order = 4,
        type = 'description',
        name = ''
    }

    settings["InitialDur"] = {
        order = 10,
        type = "range",
        name = "Initial duration",
        min = 0, max = 60, step = 1,
        desc = "Seconds to show full sized icon after the spell is cast",
        get = function(info)
            return E.db.BONK[where].Shrink.Initial
        end,
        set = function(info, value)
            E.db.BONK[where].Shrink.Initial = value
            self.BONK:Update()
        end,
    }

    settings["ResetDur"] = {
        order = 11,
        type = "range",
        name = "Reset duration",
        min = 0, max = 60, step = 1,
        desc = "Seconds to show full sized icon before cooldown is finished",
        get = function(info)
            return E.db.BONK[where].Shrink.Reset
        end,
        set = function(info, value)
            E.db.BONK[where].Shrink.Reset = value
            self.BONK:Update()
        end,
    }

    settings["TimerFontSize"] = {
        order = 12,
        type = "range",
        name = "Timer Font Size",
        min = 0, max = 30, step = 1,
        get = function(info)
            return E.db.BONK[where].Shrink.TimerFontSize
        end,
        set = function(info, value)
            E.db.BONK[where].Shrink.TimerFontSize = value
            self.BONK:Update()
        end,
    }

    settings["spacer1"] = {
        order = 15,
        type = 'description',
        name = ''
    }

    settings["DetachIcons"] = {
        order = 20,
        type = "toggle",
        name = "Detach From Cooldowns",
        get = function(info)
            return E.db.BONK[where].Shrink.Detach
        end,
        set = function(info, value)
            E.db.BONK[where].Shrink.Detach = value
            self.BONK:Update()
        end,
    }

    settings["Position"] = {
        order = 21,
        type = "select",
        name = "Position",
        values = {
            ["LEFT"] = "LEFT",
            ["RIGHT"] = "RIGHT",
            ["TOPLEFT"] = "TOPLEFT",
            ["TOPRIGHT"] = "TOPRIGHT",
            ["BOTTOMLEFT"] = "BOTTOMLEFT",
            ["BOTTOMRIGHT"] = "BOTTOMRIGHT",
        },
        disabled = function(info)
            return not E.db.BONK[where].Shrink.Detach
        end,
        get = function(info)
            return E.db.BONK[where].Shrink.Position
        end,
        set = function(info, value)
            E.db.BONK[where].Shrink.Position = value
            self.BONK:Update()
        end,
    }

    settings["PerRow"] = {
        order = 22,
        type = "range",
        name = "Icons Per Row",
        min = 1, max = 20, step = 1,
        disabled = function(info)
            local side = E.db.BONK[where].Shrink.Position

            if side == "LEFT" or side == "RIGHT" then
                return true
            end

            return not E.db.BONK[where].Shrink.Detach
        end,
        get = function(info)
            return E.db.BONK[where].Shrink.PerRow
        end,
        set = function(info, value)
            E.db.BONK[where].Shrink.PerRow = value
            self.BONK:Update()
        end,
    }

    return settings
end

function BSF:GetDefaults()
    local def = {
        ["General"] = {
            ["Stack"] = false,
            ["SeparatorY"] = 3,
            ["Debug"] = false
        },
        ["Party"] = self:GetIconDefaults(true),
        ["Arena"] = self:GetIconDefaults(false)
    }

    def.Party.Track = BCD:GetSpellDefaults()
    def.Arena.Track = BCD:GetSpellDefaults()

    return def
end

function BSF:GetIconDefaults(trinket)
    return {
        ["Trinket"] = {
            ["Enabled"] = trinket,
            ["Position"] = "LEFT",
            ["TimerFontSize"] = 15,
            ["SeparatorX"] = 0,
            ["IconSize"] = 1,
        },
        ["CD"] = {
            ["Enabled"] = true,
            ["Position"] = "LEFT",
            ["TimerFontSize"] = 15,
            ["SeparatorX"] = 10,
            ["PaddingX"] = 3,
            ["IconSize"] = 1,
        },
        ["DR"] = {
            ["Enabled"] = true,
            ["Position"] = "LEFT",
            ["TimerFontSize"] = 15,
            ["DRFontSize"] = 20,
            ["SeparatorX"] = 10,
            ["PaddingX"] = 3,
            ["IconSize"] = 1,
        },
        ["General"] = {
            ["Order"] = "spells"
        },
        ["Track"] = {},
        ["Shrink"] = {
            ["Enabled"] = true,
            ["Aura"] = true,
            ["IconSize"] = 0.5,
            ["Initial"] = 10,
            ["Reset"] = 30,
            ["TimerFontSize"] = 9,
            ["Detach"] = false,
            ["Position"] = "TOPLEFT",
            ["PerRow"] = 10
        }
    }
end
