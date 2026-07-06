local ADDON_NAME = ...
local VoiceOverTweaks = _G[ADDON_NAME]
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

-- Simple string hash (djb2), just needs to be stable/collision-resistant enough for our own key space.
local function HashText(text)
    if not text then
        return 0
    end
    local hash = 5381
    for i = 1, #text do
        hash = (hash * 33 + string.byte(text, i)) % 2147483647
    end
    return hash
end
VoiceOverTweaks.HashText = HashText

--- Returns the NPC ID and line-level key for a soundData entry, or nil if it can't be determined.
---@param soundData table
---@return number|nil npcID
---@return string|nil lineKey
function VoiceOverTweaks:GetKeysForSoundData(soundData)
    local npcID = self:GetNPCIDFromGUID(soundData.unitGUID)
    if not npcID then
        return nil, nil
    end

    local lineKey
    if soundData.questID then
        lineKey = format("%d|q%d", npcID, soundData.questID)
    else
        lineKey = format("%d|t%d", npcID, HashText(soundData.text))
    end

    return npcID, lineKey
end

function VoiceOverTweaks:ShouldBlock(soundData)
    local npcID, lineKey = self:GetKeysForSoundData(soundData)
    if not npcID then
        return false
    end

    if self.db.profile.blockedNPCs[npcID] then
        return true
    end

    if lineKey and self.db.profile.blockedLines[lineKey] then
        return true
    end

    return false
end

--- @param npcID number
--- @param name string|nil the NPC's display name, if known, for the options panel's list
function VoiceOverTweaks:BlockNPC(npcID, name)
    self.db.profile.blockedNPCs[npcID] = name or true
end

function VoiceOverTweaks:UnblockNPC(npcID)
    self.db.profile.blockedNPCs[npcID] = nil
end

--- @param lineKey string
--- @param name string|nil the speaking NPC's display name, if known, for the options panel's list
function VoiceOverTweaks:BlockLine(lineKey, name)
    self.db.profile.blockedLines[lineKey] = name or true
end

function VoiceOverTweaks:UnblockLine(lineKey)
    self.db.profile.blockedLines[lineKey] = nil
end

--- Handles `/vot silence ...`. `args` is the full slash command args table, with args[1] == "silence".
--- Every action here targets your current target, so there's no "target" keyword to type.
--- Listing/unsilencing arbitrary entries doesn't need a target, so it's options-panel-only.
function VoiceOverTweaks:HandleSilenceCommand(args)
    local sub = args[2] and args[2]:lower()

    if sub == "reset" then
        local npcID, name = self:GetTargetNPCID()
        if npcID then
            self:UnblockNPC(npcID)
            self:Print(format(L.MSG_UNSILENCED_TARGET, name or L.FALLBACK_TARGET_NAME, npcID))
        end
    elseif not sub then
        local npcID, name = self:GetTargetNPCID()
        if npcID then
            self:BlockNPC(npcID, name)
            self:Print(format(L.MSG_SILENCED_TARGET, name or L.FALLBACK_TARGET_NAME, npcID))
        end
    else
        self:PrintHelp()
    end
end
