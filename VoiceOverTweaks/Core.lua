local ADDON_NAME = ...

---@class VoiceOverTweaks : AceAddon, AceConsole-3.0
local VoiceOverTweaks = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0")
_G[ADDON_NAME] = VoiceOverTweaks

local defaults = {
    profile = {
        defaultDelay = 1,
        delays = {},       -- [npcID] = seconds
        blockedNPCs = {},  -- [npcID] = true
        blockedLines = {}, -- ["npcID|q<questID>"] = true, ["npcID|t<texthash>"] = true
    },
}

function VoiceOverTweaks:OnInitialize()
    -- Passing `true` makes every character default to a single shared "Default" profile,
    -- so tweaks are account-wide out of the box, while still allowing a character to be
    -- switched onto its own separate profile via the "Profiles" tab in `/vot options`.
    self.db = LibStub("AceDB-3.0"):New("VoiceOverTweaksDB", defaults, true)

    self:RegisterChatCommand("vot", "HandleSlashCommand")

    self:InstallHook()

    local buttonInstalled = self:InstallMuteButton()
    if not buttonInstalled then
        -- VoiceOver either isn't installed or hasn't loaded VoiceOver.lua yet (load order can't be
        -- guaranteed via OptionalDeps alone). Defer and retry once ADDON_LOADED fires for it.
        self:RegisterEvent("ADDON_LOADED", "OnAddonLoaded")
    end
end

function VoiceOverTweaks:OnAddonLoaded(event, addon)
    if self:InstallMuteButton() then
        self:UnregisterEvent("ADDON_LOADED")
    end
end

--- Resolves the NPC ID from a unit GUID via VoiceOver's own GUID helpers.
--- Returns nil for GUID types that don't carry an ID (e.g. Player) or if VoiceOver's API is unavailable.
---@param guid string|nil
---@return number|nil npcID
function VoiceOverTweaks:GetNPCIDFromGUID(guid)
    if not guid or not VoiceOver or not VoiceOver.Utils or not VoiceOver.Enums then
        return nil
    end

    local Utils, Enums = VoiceOver.Utils, VoiceOver.Enums

    local ok, guidType = pcall(Utils.GetGUIDType, Utils, guid)
    if not ok or not guidType or not Enums.GUID:CanHaveID(guidType) then
        return nil
    end

    local ok2, id = pcall(Utils.GetIDFromGUID, Utils, guid)
    if ok2 then
        return id
    end
    return nil
end

--- Returns the NPC ID of the player's current target, printing a chat message if unavailable.
---@return number|nil npcID
---@return string|nil name
function VoiceOverTweaks:GetTargetNPCID()
    if not UnitExists("target") then
        self:Print("You have no target.")
        return nil
    end

    local npcID = self:GetNPCIDFromGUID(UnitGUID("target"))
    if not npcID then
        self:Print("Your target isn't a valid NPC (must be a creature, vehicle, or game object).")
        return nil
    end

    return npcID, UnitName("target")
end

--- Replaces VoiceOver.SoundQueue:AddSoundToQueue with a wrapper that first lets the silencer
--- drop blocked lines entirely, then lets the delay feature hold back an interaction's opening
--- greeting/gossip line so it doesn't talk over the NPC's native voice bark. Does nothing if
--- VoiceOver isn't loaded. Any failure inside the wrapper falls back to calling through to the
--- original function immediately, so a future VoiceOver update can't hard-break this.
function VoiceOverTweaks:InstallHook()
    if not VoiceOver or not VoiceOver.SoundQueue or type(VoiceOver.SoundQueue.AddSoundToQueue) ~= "function" then
        return false
    end

    local SoundQueue = VoiceOver.SoundQueue
    local original = SoundQueue.AddSoundToQueue

    SoundQueue.AddSoundToQueue = function(self, soundData)
        local blocked, handled = false, false

        local ok = pcall(function()
            blocked = VoiceOverTweaks:ShouldBlock(soundData)
            if blocked then
                return
            end

            local isGreeting = VoiceOver.Enums.SoundEvent:IsGossipEvent(soundData.event)
            local queueWasEmpty = (#self.sounds == 0)

            if isGreeting and queueWasEmpty then
                local delaySeconds = VoiceOverTweaks:GetDelayFor(soundData) or 0
                if delaySeconds > 0 then
                    handled = true
                    C_Timer.After(delaySeconds, function()
                        original(self, soundData)
                    end)
                end
            end
        end)

        if not ok then
            original(self, soundData)
            return
        end

        if blocked or handled then
            return
        end

        original(self, soundData)
    end

    return true
end

--- Everything that doesn't need a live game-world target (default delay, per-NPC lists,
--- profile management) lives in the options panel; the slash command only covers actions
--- tied to your current target, plus opening that panel.
function VoiceOverTweaks:PrintHelp()
    self:Print("Usage:")
    print("  /vot delay <seconds> - Set a delay override for your current target")
    print("  /vot delay reset - Remove your current target's delay override")
    print("  /vot silence - Silence your current target")
    print("  /vot silence reset - Unsilence your current target")
    print("  /vot options")
end

function VoiceOverTweaks:HandleSlashCommand(input)
    local args = {}
    for word in input:gmatch("%S+") do
        table.insert(args, word)
    end

    local command = args[1] and args[1]:lower()

    if not command then
        self:PrintHelp()
        return
    end

    if command == "delay" then
        self:HandleDelayCommand(args)
    elseif command == "silence" then
        self:HandleSilenceCommand(args)
    elseif command == "options" then
        self:OpenOptions()
    else
        self:PrintHelp()
    end
end
