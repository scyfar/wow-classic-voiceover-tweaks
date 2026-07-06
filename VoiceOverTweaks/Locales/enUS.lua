-- Default locale (en_US). This is the addon's source-of-truth text: every other Locales/*.lua
-- file only needs to override the keys it has translations for, falling back to this one.
local L = LibStub("AceLocale-3.0"):NewLocale("VoiceOverTweaks", "enUS", true)
if not L then return end

-- Slash command messages
L.MSG_NO_TARGET = "You have no target."
L.MSG_INVALID_TARGET = "Your target isn't a valid NPC (must be a creature, vehicle, or game object)."
L.MSG_USAGE_HEADER = "Usage:"
L.MSG_USAGE_DELAY_SET = "  /vot delay <seconds> - Set a delay override for your current target"
L.MSG_USAGE_DELAY_RESET = "  /vot delay reset - Remove your current target's delay override"
L.MSG_USAGE_SILENCE_SET = "  /vot silence - Silence your current target"
L.MSG_USAGE_SILENCE_RESET = "  /vot silence reset - Unsilence your current target"
L.MSG_USAGE_OPTIONS = "  /vot options"

L.MSG_DELAY_SET = "Set delay override for NPC %d to %.1fs."
L.MSG_DELAY_NONE = "NPC %d has no delay override."
L.MSG_DELAY_REMOVED = "Removed delay override for NPC %d. Falling back to default (%.1fs)."

L.MSG_SILENCED_TARGET = "Silenced all VoiceOver lines from %s (NPC ID %d)."
L.MSG_UNSILENCED_TARGET = "Unsilenced %s (NPC ID %d)."
L.MSG_SILENCED_LINE = "Silenced this line from %s."
L.FALLBACK_TARGET_NAME = "target"
L.FALLBACK_NPC_NAME = "NPC"

-- Mute button tooltip
L.TOOLTIP_TITLE = "Silence this NPC"
L.TOOLTIP_LEFT_CLICK = "Left-click: silence every line from this NPC."
L.TOOLTIP_RIGHT_CLICK = "Right-click: silence just this line."

-- Options panel
L.UNKNOWN_NAME = "Unknown"
L.LINE_QUEST = "Quest %s"
L.LINE_TEXT = "Text #%s"

L.ROW_DELAY_OVERRIDE = "%d - %s (%.1fs)"
L.ROW_BLOCKED_NPC = "%d - %s"
L.ROW_BLOCKED_LINE = "%s - %s (%s)"

L.TAB_DELAY = "Delay"
L.DELAY_DESCRIPTION = "Delays an NPC's first VoiceOver line so it doesn't talk over their native Blizzard greeting.\n"
L.DELAY_DEFAULT_LABEL = "Default delay (seconds)"
L.DELAY_DEFAULT_DESC = "Applied to any NPC without its own override below."
L.DELAY_TARGET_HELP = "Use |cffffd200/vot delay <seconds>|r to set an override for your current target, or |cffffd200/vot delay reset|r to remove it.\n"
L.DELAY_OVERRIDES_GROUP = "Per-NPC Overrides"
L.DELAY_OVERRIDE_REMOVE_DESC = "Click to remove this NPC's delay override."
L.DELAY_OVERRIDES_EMPTY = "No per-NPC delay overrides set."

L.TAB_SILENCE = "Silence"
L.SILENCE_DESCRIPTION = "Silence specific NPCs or lines spoken by the VoiceOver addon. Click an entry below to unsilence it.\n"
L.SILENCE_TARGET_HELP = "Use |cffffd200/vot silence|r to silence your current target's NPC entirely, or |cffffd200/vot silence reset|r to unsilence it.\n"
L.SILENCE_NPCS_GROUP = "Silenced NPCs"
L.SILENCE_LINES_GROUP = "Silenced Lines"
L.SILENCE_NPC_REMOVE_DESC = "Click to unsilence this NPC."
L.SILENCE_NPCS_EMPTY = "No NPCs are fully silenced."
L.SILENCE_LINE_REMOVE_DESC = "Click to unsilence this line."
L.SILENCE_LINES_EMPTY = "No individual lines are silenced."
