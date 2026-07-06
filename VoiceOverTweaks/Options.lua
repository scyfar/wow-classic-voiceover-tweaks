local ADDON_NAME = ...
local VoiceOverTweaks = _G[ADDON_NAME]
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

--- A blank full-width line, used to put a bit of breathing room between unrelated widgets
--- (AceConfig otherwise packs controls tightly with no vertical margin of their own).
---@param order number
local function Spacer(order)
    return { type = "description", order = order, name = " ", width = "full" }
end

---@param t table
---@return number count of entries in a hash table (e.g. keyed by npcID), which has no #t
local function CountEntries(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

--- A button label with the live entry count appended, e.g. "Manage Overrides... (3)", so it's
--- obvious there's nothing to manage without having to open the dialog first.
---@param label string
---@param countFn fun(): number
local function ManageButtonLabel(label, countFn)
    return function()
        return format("%s (%d)", label, countFn())
    end
end

local options = {
    type = "group",
    name = "VoiceOverTweaks",
    childGroups = "tab",
    args = {
        delay = {
            type = "group",
            order = 1,
            name = L.TAB_DELAY,
            args = {
                description = {
                    type = "description",
                    order = 1,
                    name = L.DELAY_DESCRIPTION,
                },
                defaultDelay = {
                    type = "range",
                    order = 2,
                    name = L.DELAY_DEFAULT_LABEL,
                    desc = L.DELAY_DEFAULT_DESC,
                    min = 0,
                    max = 10,
                    step = 0.1,
                    get = function() return VoiceOverTweaks.db.profile.defaultDelay end,
                    set = function(_, value) VoiceOverTweaks.db.profile.defaultDelay = value end,
                },
                spacer1 = Spacer(3),
                targetHelp = {
                    type = "description",
                    order = 4,
                    name = L.DELAY_TARGET_HELP,
                },
                manageOverrides = {
                    type = "execute",
                    order = 5,
                    name = ManageButtonLabel(L.DELAY_OVERRIDES_MANAGE_BUTTON,
                        function() return CountEntries(VoiceOverTweaks.db.profile.delays) end),
                    width = "full",
                    func = function() VoiceOverTweaks:ShowDelayOverridesDialog() end,
                },
            },
        },
        silence = {
            type = "group",
            order = 2,
            name = L.TAB_SILENCE,
            args = {
                description = {
                    type = "description",
                    order = 1,
                    name = L.SILENCE_DESCRIPTION,
                },
                spacer1 = Spacer(2),
                targetHelp = {
                    type = "description",
                    order = 3,
                    name = L.SILENCE_TARGET_HELP,
                },
                manageBlockedNPCs = {
                    type = "execute",
                    order = 4,
                    name = ManageButtonLabel(L.SILENCE_NPCS_MANAGE_BUTTON,
                        function() return CountEntries(VoiceOverTweaks.db.profile.blockedNPCs) end),
                    width = 1.8,
                    func = function() VoiceOverTweaks:ShowSilencedNPCsDialog() end,
                },
                manageBlockedLines = {
                    type = "execute",
                    order = 5,
                    name = ManageButtonLabel(L.SILENCE_LINES_MANAGE_BUTTON,
                        function() return CountEntries(VoiceOverTweaks.db.profile.blockedLines) end),
                    width = 1.8,
                    func = function() VoiceOverTweaks:ShowSilencedLinesDialog() end,
                },
            },
        },
        -- Filled in lazily below, once VoiceOverTweaks.db exists (AceDB is created in OnInitialize,
        -- which runs after this file, so it can't be built at file-load time).
        profiles = nil,
    },
}

local function RefreshOptionsTable()
    if not options.args.profiles then
        options.args.profiles = AceDBOptions:GetOptionsTable(VoiceOverTweaks.db)
        options.args.profiles.order = 3
    end

    AceConfigDialog:ConfigTableChanged(nil, "VoiceOverTweaks")
end

AceConfig:RegisterOptionsTable("VoiceOverTweaks", function()
    RefreshOptionsTable()
    return options
end)

AceConfigDialog:AddToBlizOptions("VoiceOverTweaks", "VoiceOverTweaks")

function VoiceOverTweaks:OpenOptions()
    RefreshOptionsTable()
    AceConfigDialog:Open("VoiceOverTweaks")
end
