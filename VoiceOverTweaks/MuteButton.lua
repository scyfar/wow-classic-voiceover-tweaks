local ADDON_NAME = ...
local VoiceOverTweaks = _G[ADDON_NAME]

-- Injects a small "mute this speaker" button onto VoiceOver's on-screen SoundQueueUI frame.
-- Entirely additive: creates a new frame parented to VoiceOver's frame, never edits VoiceOver's files.
-- Best-effort: if VoiceOver's SoundQueueUI shape has changed, this silently does nothing.

local button

local function GetCurrentSoundData()
    return VoiceOver.SoundQueue:GetCurrentSound()
end

local function UpdateButton()
    if not button then
        return
    end

    local soundData = GetCurrentSoundData()
    local npcID = soundData and VoiceOverTweaks:GetKeysForSoundData(soundData)

    if not npcID then
        button:Hide()
        return
    end

    button:Show()

    local isBlocked = VoiceOverTweaks.db.profile.blockedNPCs[npcID]
    if isBlocked then
        button:SetAlpha(0.4)
    else
        button:SetAlpha(1)
    end
end

local function OnClick(self, mouseButton)
    local soundData = GetCurrentSoundData()
    if not soundData then
        return
    end

    local npcID, lineKey = VoiceOverTweaks:GetKeysForSoundData(soundData)
    if not npcID then
        return
    end

    if mouseButton == "RightButton" then
        -- Right-click: mute just this line (quest/gossip text), left in place otherwise.
        if lineKey then
            VoiceOverTweaks:BlockLine(lineKey, soundData.name)
            VoiceOverTweaks:Print(format("Silenced this line from %s.", soundData.name or "NPC"))
        end
    else
        VoiceOverTweaks:BlockNPC(npcID, soundData.name)
        VoiceOverTweaks:Print(format("Silenced all VoiceOver lines from %s.", soundData.name or "NPC"))
    end

    -- Immediately stop the current line rather than waiting for the next queue event.
    VoiceOver.SoundQueue:RemoveSoundFromQueue(soundData)
    UpdateButton()
end

local function CreateButton()
    local portrait = VoiceOver.SoundQueueUI.frame.portrait

    button = CreateFrame("Button", "VoiceOverTweaksMuteButton", portrait)
    button:SetSize(20, 20)
    button:SetPoint("TOPRIGHT", portrait, "TOPRIGHT", -2, -2)
    button:SetFrameLevel(portrait.pause:GetFrameLevel() + 2)

    button:SetNormalTexture([[Interface\Common\VoiceChat-Muted]])
    button:SetHighlightTexture([[Interface\Common\VoiceChat-Muted]], "ADD")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button:SetScript("OnClick", OnClick)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Silence this NPC", 1, 1, 1)
        GameTooltip:AddLine("Left-click: silence every line from this NPC.", nil, nil, nil, true)
        GameTooltip:AddLine("Right-click: silence just this line.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    hooksecurefunc(VoiceOver.SoundQueueUI, "UpdateSoundQueueDisplay", UpdateButton)

    UpdateButton()
end

function VoiceOverTweaks:InstallMuteButton()
    if button then
        return true
    end

    if not VoiceOver or not VoiceOver.SoundQueueUI or not VoiceOver.SoundQueueUI.frame or not VoiceOver.SoundQueueUI.frame.portrait then
        return false
    end

    local ok = pcall(CreateButton)
    return ok and button ~= nil
end
