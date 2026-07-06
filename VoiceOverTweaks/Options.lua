local ADDON_NAME = ...
local VoiceOverTweaks = _G[ADDON_NAME]

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

--- Renders a blockedNPCs/blockedLines value (a display name, or `true` if none was known yet
--- when it was silenced) as a display string.
local function DisplayName(name)
    if type(name) == "string" then
        return name
    end
    return "Unknown"
end

--- A blockedLines key looks like "<npcID>|q<questID>" or "<npcID>|t<textHash>". Split it back
--- into the NPC ID and a human-readable description of which line it is, for the options list.
---@param lineKey string
---@return number|nil npcID
---@return string detail
local function ParseLineKey(lineKey)
    local npcIDStr, kind, num = lineKey:match("^(%d+)|([qt])(%d+)$")
    if kind == "q" then
        return tonumber(npcIDStr), format("Quest %s", num)
    elseif kind == "t" then
        return tonumber(npcIDStr), format("Text #%s", num)
    end
    return nil, lineKey
end

--- Builds a list of clickable plain-text entries, one per row, each removed by clicking it.
--- Each entry's whole line is the button (an AceGUI "execute" widget renders as plain text
--- with a button's click behavior, not an editable field).
---@param rows table[] array of `{ remove = fun(), label = string }`
---@param removeDesc string tooltip for each entry
---@param emptyText string shown when there are no rows
local function BuildEntryArgs(rows, removeDesc, emptyText)
    local args = {}
    for order, row in ipairs(rows) do
        args["entry" .. order] = {
            type = "execute",
            order = order,
            name = row.label,
            desc = removeDesc,
            width = "full",
            func = row.remove,
        }
    end
    if #rows == 0 then
        args.none = { type = "description", order = 1, name = emptyText }
    end
    return args
end

--- Builds the "<id> - <name> (<seconds>s)" rows for the delay-overrides list, sorted by NPC ID.
local function BuildDelayOverrideRows()
    local npcIDs = {}
    for npcID in pairs(VoiceOverTweaks.db.profile.delays) do
        table.insert(npcIDs, npcID)
    end
    table.sort(npcIDs)

    local rows = {}
    for _, npcID in ipairs(npcIDs) do
        local override = VoiceOverTweaks.db.profile.delays[npcID]
        table.insert(rows, {
            remove = function() VoiceOverTweaks:RemoveDelayOverride(npcID) end,
            label = format("%d - %s (%.1fs)", npcID, DisplayName(override.name), override.seconds),
        })
    end
    return rows
end

--- Builds the "<id> - <name>" rows for the silenced-NPCs list, sorted by NPC ID.
local function BuildBlockedNPCRows()
    local npcIDs = {}
    for npcID in pairs(VoiceOverTweaks.db.profile.blockedNPCs) do
        table.insert(npcIDs, npcID)
    end
    table.sort(npcIDs)

    local rows = {}
    for _, npcID in ipairs(npcIDs) do
        table.insert(rows, {
            remove = function() VoiceOverTweaks:UnblockNPC(npcID) end,
            label = format("%d - %s", npcID, DisplayName(VoiceOverTweaks.db.profile.blockedNPCs[npcID])),
        })
    end
    return rows
end

--- Builds the "<npc id> - <name> (<line>)" rows for the silenced-lines list, sorted by line key.
local function BuildBlockedLineRows()
    local lineKeys = {}
    for lineKey in pairs(VoiceOverTweaks.db.profile.blockedLines) do
        table.insert(lineKeys, lineKey)
    end
    table.sort(lineKeys)

    local rows = {}
    for _, lineKey in ipairs(lineKeys) do
        local npcID, detail = ParseLineKey(lineKey)
        table.insert(rows, {
            remove = function() VoiceOverTweaks:UnblockLine(lineKey) end,
            label = format("%s - %s (%s)", npcID and tostring(npcID) or "?",
                DisplayName(VoiceOverTweaks.db.profile.blockedLines[lineKey]), detail),
        })
    end
    return rows
end

local options = {
    type = "group",
    name = "VoiceOverTweaks",
    childGroups = "tab",
    args = {
        delay = {
            type = "group",
            order = 1,
            name = "Delay",
            args = {
                description = {
                    type = "description",
                    order = 1,
                    name = "Delays an NPC's first VoiceOver line so it doesn't talk over their native Blizzard greeting.\n",
                },
                defaultDelay = {
                    type = "range",
                    order = 2,
                    name = "Default delay (seconds)",
                    desc = "Applied to any NPC without its own override below.",
                    min = 0,
                    max = 10,
                    step = 0.1,
                    get = function() return VoiceOverTweaks.db.profile.defaultDelay end,
                    set = function(_, value) VoiceOverTweaks.db.profile.defaultDelay = value end,
                },
                targetHelp = {
                    type = "description",
                    order = 3,
                    name = "Use |cffffd200/vot delay <seconds>|r to set an override for your current target, or |cffffd200/vot delay reset|r to remove it.\n",
                },
                overrides = {
                    type = "group",
                    order = 4,
                    name = "Per-NPC Overrides",
                    inline = true,
                    args = {},
                    get = false,
                },
            },
        },
        silence = {
            type = "group",
            order = 2,
            name = "Silence",
            args = {
                description = {
                    type = "description",
                    order = 1,
                    name = "Silence specific NPCs or lines spoken by the VoiceOver addon. Click an entry below to unsilence it.\n",
                },
                targetHelp = {
                    type = "description",
                    order = 2,
                    name = "Use |cffffd200/vot silence|r to silence your current target's NPC entirely, or |cffffd200/vot silence reset|r to unsilence it.\n",
                },
                blockedNPCs = {
                    type = "group",
                    order = 3,
                    name = "Silenced NPCs",
                    inline = true,
                    args = {},
                    get = false,
                },
                blockedLines = {
                    type = "group",
                    order = 4,
                    name = "Silenced Lines",
                    inline = true,
                    args = {},
                    get = false,
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

    options.args.delay.args.overrides.args = BuildEntryArgs(
        BuildDelayOverrideRows(), "Click to remove this NPC's delay override.", "No per-NPC delay overrides set.")

    options.args.silence.args.blockedNPCs.args = BuildEntryArgs(
        BuildBlockedNPCRows(), "Click to unsilence this NPC.", "No NPCs are fully silenced.")
    options.args.silence.args.blockedLines.args = BuildEntryArgs(
        BuildBlockedLineRows(), "Click to unsilence this line.", "No individual lines are silenced.")

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
