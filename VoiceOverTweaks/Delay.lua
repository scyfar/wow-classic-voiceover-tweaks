local ADDON_NAME = ...
local VoiceOverTweaks = _G[ADDON_NAME]
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

---@param soundData SoundData
---@return number delaySeconds
function VoiceOverTweaks:GetDelayFor(soundData)
    local npcID = self:GetNPCIDFromGUID(soundData and soundData.unitGUID)
    local override = npcID and self.db.profile.delays[npcID]
    if override then
        return override.seconds
    end
    return self.db.profile.defaultDelay
end

--- Removes a per-NPC delay override, if any. Shared by the target-reset slash command and
--- the options panel's override list.
---@param npcID number
function VoiceOverTweaks:RemoveDelayOverride(npcID)
    self.db.profile.delays[npcID] = nil
end

function VoiceOverTweaks:SetTargetDelayOverride(seconds)
    if not seconds or seconds < 0 then
        self:PrintHelp()
        return
    end

    local npcID, name = self:GetTargetNPCID()
    if not npcID then
        return
    end

    self.db.profile.delays[npcID] = { seconds = seconds, name = name }
    self:Print(format(L.MSG_DELAY_SET, npcID, seconds))
end

function VoiceOverTweaks:ResetTargetDelayOverride()
    local npcID = self:GetTargetNPCID()
    if not npcID then
        return
    end

    if self.db.profile.delays[npcID] == nil then
        self:Print(format(L.MSG_DELAY_NONE, npcID))
        return
    end

    self:RemoveDelayOverride(npcID)
    self:Print(format(L.MSG_DELAY_REMOVED, npcID, self.db.profile.defaultDelay))
end

--- Handles `/vot delay ...`. `args` is the full slash command args table, with args[1] == "delay".
--- Every remaining action here targets your current target, so there's no "target" keyword to type.
--- Setting the default delay and listing overrides don't need a target, so they're options-panel-only.
function VoiceOverTweaks:HandleDelayCommand(args)
    local sub = args[2] and args[2]:lower()

    if sub == "reset" then
        self:ResetTargetDelayOverride()
    else
        self:SetTargetDelayOverride(tonumber(args[2]))
    end
end
