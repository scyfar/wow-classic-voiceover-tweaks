local ADDON_NAME = ...
local VoiceOverTweaks = _G[ADDON_NAME]
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local ScrollingTable = LibStub("ScrollingTable")

-- Sortable/searchable popup windows for the Delay Overrides / Silenced NPCs / Silenced Lines
-- lists, built on top of lib-st (ScrollingTable) instead of cramming one AceConfig button per
-- entry into the options panel.

--- Renders a blockedNPCs/blockedLines/delays name (a display name, or `true`/nil if none was
--- known yet when it was recorded) as a display string.
local function DisplayName(name)
    if type(name) == "string" then
        return name
    end
    return L.UNKNOWN_NAME
end

--- A blockedLines key looks like "<npcID>|q<questID>" or "<npcID>|t<textHash>". Split it back
--- into the NPC ID and a human-readable description of which line it is, for the dialog.
---@param lineKey string
---@return number|nil npcID
---@return string detail
local function ParseLineKey(lineKey)
    local npcIDStr, kind, num = lineKey:match("^(%d+)|([qt])(%d+)$")
    if kind == "q" then
        return tonumber(npcIDStr), format(L.LINE_QUEST, num)
    elseif kind == "t" then
        return tonumber(npcIDStr), format(L.LINE_TEXT, num)
    end
    return nil, lineKey
end

--- Builds the lib-st data rows for the delay-overrides dialog: {ID, Name, Delay}.
local function BuildDelayOverrideSTData()
    local npcIDs = {}
    for npcID in pairs(VoiceOverTweaks.db.profile.delays) do
        table.insert(npcIDs, npcID)
    end
    table.sort(npcIDs)

    local data = {}
    for _, npcID in ipairs(npcIDs) do
        local override = VoiceOverTweaks.db.profile.delays[npcID]
        local name = DisplayName(override.name)
        table.insert(data, {
            cols = {
                { value = npcID },
                { value = name },
                { value = override.seconds },
            },
            remove = function() VoiceOverTweaks:RemoveDelayOverride(npcID) end,
            searchText = format("%d %s", npcID, name):lower(),
        })
    end
    return data
end

--- Builds the lib-st data rows for the silenced-NPCs dialog: {ID, Name}.
local function BuildBlockedNPCSTData()
    local npcIDs = {}
    for npcID in pairs(VoiceOverTweaks.db.profile.blockedNPCs) do
        table.insert(npcIDs, npcID)
    end
    table.sort(npcIDs)

    local data = {}
    for _, npcID in ipairs(npcIDs) do
        local name = DisplayName(VoiceOverTweaks.db.profile.blockedNPCs[npcID])
        table.insert(data, {
            cols = {
                { value = npcID },
                { value = name },
            },
            remove = function() VoiceOverTweaks:UnblockNPC(npcID) end,
            searchText = format("%d %s", npcID, name):lower(),
        })
    end
    return data
end

--- Builds the lib-st data rows for the silenced-lines dialog: {NPC ID, Name, Line}.
local function BuildBlockedLineSTData()
    local lineKeys = {}
    for lineKey in pairs(VoiceOverTweaks.db.profile.blockedLines) do
        table.insert(lineKeys, lineKey)
    end
    table.sort(lineKeys)

    local data = {}
    for _, lineKey in ipairs(lineKeys) do
        local npcID, detail = ParseLineKey(lineKey)
        local name = DisplayName(VoiceOverTweaks.db.profile.blockedLines[lineKey])
        table.insert(data, {
            cols = {
                { value = npcID or 0 },
                { value = name },
                { value = detail },
            },
            remove = function() VoiceOverTweaks:UnblockLine(lineKey) end,
            searchText = format("%s %s %s", npcID and tostring(npcID) or "", name, detail):lower(),
        })
    end
    return data
end

--- Lazily creates (and caches) the sort-arrow icon texture for a header column button.
--- Uses Blizzard's own Auction House sort-arrow atlas rather than a font glyph, since the
--- Classic UI font doesn't contain Unicode triangle characters.
---@param headerCol table the header column's Button frame
local function GetOrCreateSortArrow(headerCol)
    local arrow = headerCol.sortArrow
    if not arrow then
        arrow = headerCol:CreateTexture(nil, "OVERLAY")
        arrow:SetAtlas("auctionhouse-ui-sortarrow")
        arrow:SetSize(12, 12)
        arrow:SetPoint("RIGHT", headerCol, "RIGHT", -4, 0)
        headerCol.sortArrow = arrow
    end
    return arrow
end

--- Shows a sort-direction arrow icon on whichever column header is currently the active sort
--- column (and hides it on the rest), since lib-st itself only tracks sort state internally
--- without indicating it visually.
---@param st table the ScrollingTable instance
---@param columnSpecs table the same column info passed to CreateST
local function UpdateHeaderArrows(st, columnSpecs)
    local headerRow = st.head
    if not headerRow then
        return
    end
    for i, col in ipairs(columnSpecs) do
        local headerCol = headerRow.cols[i]
        if headerCol then
            local arrow = GetOrCreateSortArrow(headerCol)
            if col.sort == ScrollingTable.SORT_ASC then
                arrow:SetTexCoord(0, 1, 0, 1)
                arrow:Show()
            elseif col.sort == ScrollingTable.SORT_DSC then
                arrow:SetTexCoord(0, 1, 1, 0)
                arrow:Show()
            else
                arrow:Hide()
            end
        end
    end
end

local HEADER_TEXT_LEFT_PADDING = 9    -- extra room after the divider, so text doesn't hug it
local HEADER_TEXT_RIGHT_PADDING = 2.5 -- lib-st's own default padding
local HEADER_HOVER_COLOR = { 1, 0.82, 0 }
local HEADER_TEXT_COLOR = { 1, 1, 1 }

--- One-time setup for each header column button: a golden mouseover font color (lib-st doesn't
--- set up any hover feedback itself) and a thin divider line on its right edge, so adjacent
--- header columns - and which one the sort arrow belongs to - are visually distinguishable.
---@param st table the ScrollingTable instance
---@param columnSpecs table the same column info passed to CreateST
local function SetupHeaderColumns(st, columnSpecs)
    local headerRow = st.head
    if not headerRow then
        return
    end
    local numCols = #columnSpecs
    for i in ipairs(columnSpecs) do
        local headerCol = headerRow.cols[i]
        if headerCol then
            local fs = headerCol:GetFontString()
            if fs then
                headerCol:SetScript("OnEnter", function()
                    fs:SetTextColor(unpack(HEADER_HOVER_COLOR))
                end)
                headerCol:SetScript("OnLeave", function()
                    fs:SetTextColor(unpack(HEADER_TEXT_COLOR))
                end)
            end

            if i < numCols then
                local divider = headerCol:CreateTexture(nil, "ARTWORK")
                divider:SetColorTexture(0.5, 0.5, 0.5, 0.5)
                divider:SetWidth(1)
                divider:SetPoint("TOPRIGHT", headerCol, "TOPRIGHT", 0, -3)
                divider:SetPoint("BOTTOMRIGHT", headerCol, "BOTTOMRIGHT", 0, 3)
            end

            -- Give columns after the first extra left padding so their name doesn't sit right
            -- up against the divider from the previous column.
            if i > 1 and fs then
                fs:ClearAllPoints()
                fs:SetPoint("LEFT", headerCol, "LEFT", HEADER_TEXT_LEFT_PADDING, 0)
                fs:SetPoint("RIGHT", headerCol, "RIGHT", -HEADER_TEXT_RIGHT_PADDING, 0)
            end
        end
    end
end

local ZEBRA_STRIPE_COLOR = { 1, 1, 1, 0.05 }

--- Gives every odd display row (1st, 3rd, ...) a subtle background tint, so long lists are
--- easier to scan. lib-st's row frames (st.rows) are created once and reused as data scrolls
--- through them, so this only needs to run once per dialog, not on every refresh.
---@param st table the ScrollingTable instance
local function SetupZebraStripes(st)
    for i, row in ipairs(st.rows) do
        if i % 2 == 1 then
            local stripe = row:CreateTexture(nil, "BACKGROUND")
            stripe:SetAllPoints(row)
            stripe:SetColorTexture(unpack(ZEBRA_STRIPE_COLOR))
        end
    end
end

local dialogs = {}

--- Creates the popup window for `key`: a title bar, a search box, and a lib-st ScrollingTable
--- where clicking anywhere on a row removes that entry (a tooltip on hover says so).
--- `columnSpecs` is lib-st column info; `buildData` returns fresh lib-st rows on every refresh.
local function CreateDialog(key, title, columnSpecs, buildData)
    local frame = CreateFrame("Frame", "VoiceOverTweaks" .. key .. "Dialog", UIParent,
        BackdropTemplateMixin and "BackdropTemplate")
    -- FULLSCREEN_DIALOG sits above the Blizzard Settings/Interface Options window (which itself
    -- uses FULLSCREEN), so this always opens on top of it instead of behind.
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:Hide()
    tinsert(UISpecialFrames, frame:GetName()) -- lets Escape close it, like any other Blizzard dialog

    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleText:SetPoint("TOP", frame, "TOP", 0, -14)
    titleText:SetText(title)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    closeButton:SetScript("OnClick", function() frame:Hide() end)

    local searchLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    searchLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -40)
    searchLabel:SetText(L.DIALOG_SEARCH_LABEL)

    local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetAutoFocus(false)
    searchBox:SetHeight(20)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
    searchBox:SetPoint("RIGHT", frame, "RIGHT", -16, 0)

    local st = ScrollingTable:CreateST(columnSpecs, 20, 22, nil, frame)
    st.frame:ClearAllPoints()
    -- Leave room above the table for the search row *and* lib-st's own header row (which it
    -- anchors directly above st.frame, rowHeight tall) so neither overlaps the search box.
    st.frame:SetPoint("TOP", frame, "TOP", 0, -(40 + 20 + 10 + 22))
    SetupZebraStripes(st)

    local dialog
    dialog = {
        frame = frame,
        st = st,
        searchBox = searchBox,
        Refresh = function(self)
            self.st:SetData(buildData())
        end,
    }

    -- lib-st's default OnClick handles header-click sorting (when there's no row/realrow); a
    -- click on any actual row instead removes that entry outright. Row hover keeps the
    -- library's default highlight (returning false lets it run) and additionally shows a
    -- "click to remove" tooltip.
    st:RegisterEvents({
        OnClick = function(rowFrame, cellFrame, data, cols, row, realrow, column, tbl, button, ...)
            if row and realrow then
                if button == "LeftButton" then
                    data[realrow].remove()
                    dialog:Refresh()
                    return true
                end
                return false
            end

            st.DefaultEvents.OnClick(rowFrame, cellFrame, data, cols, row, realrow, column, tbl, button, ...)
            UpdateHeaderArrows(st, columnSpecs)
            return true
        end,
        OnEnter = function(rowFrame, cellFrame, data, cols, row, realrow)
            if row and realrow then
                GameTooltip:SetOwner(cellFrame, "ANCHOR_CURSOR")
                GameTooltip:SetText(L.ROW_REMOVE_TOOLTIP)
                GameTooltip:Show()
            end
            return false
        end,
        OnLeave = function(rowFrame, cellFrame, data, cols, row, realrow)
            GameTooltip:Hide()
            return false
        end,
    })

    -- Must run after RegisterEvents: lib-st's RegisterEvents also (re)assigns OnEnter/OnLeave
    -- scripts on the header columns, which would otherwise clobber the hover color set here.
    SetupHeaderColumns(st, columnSpecs)

    UpdateHeaderArrows(st, columnSpecs)

    searchBox:SetScript("OnTextChanged", function(self)
        local query = self:GetText():lower()
        if query == "" then
            st:SetFilter(function() return true end)
        else
            st:SetFilter(function(_, rowdata) return rowdata.searchText:find(query, 1, true) ~= nil end)
        end
    end)

    local tableWidth, tableHeight = st.frame:GetWidth(), st.frame:GetHeight()
    frame:SetSize(math.max(tableWidth + 32, 480), math.max(tableHeight + 92 + 24, 420))

    dialogs[key] = dialog
    return dialog
end

--- Opens (creating on first use) the popup window identified by `key`.
---@param key string unique per dialog, used as the frame name and cache key
---@param title string dialog title
---@param columnSpecs table lib-st column info; last column is the remove action
---@param buildData fun(): table lib-st rows, called fresh on every open/refresh
function VoiceOverTweaks:ShowTableDialog(key, title, columnSpecs, buildData)
    local dialog = dialogs[key] or CreateDialog(key, title, columnSpecs, buildData)
    dialog.searchBox:SetText("")
    dialog.st:SetFilter(function() return true end)
    dialog:Refresh()
    dialog.frame:Show()
    dialog.frame:Raise()
end

function VoiceOverTweaks:ShowDelayOverridesDialog()
    self:ShowTableDialog("DelayOverrides", L.DIALOG_TITLE_DELAY_OVERRIDES, {
        { name = L.COL_ID,    width = 70,  align = "LEFT", defaultsort = ScrollingTable.SORT_ASC, sort = ScrollingTable.SORT_ASC },
        { name = L.COL_NAME,  width = 260, align = "LEFT" },
        { name = L.COL_DELAY, width = 110, align = "RIGHT" },
    }, BuildDelayOverrideSTData)
end

function VoiceOverTweaks:ShowSilencedNPCsDialog()
    self:ShowTableDialog("SilencedNPCs", L.DIALOG_TITLE_SILENCED_NPCS, {
        { name = L.COL_ID,   width = 70,  align = "LEFT", defaultsort = ScrollingTable.SORT_ASC, sort = ScrollingTable.SORT_ASC },
        { name = L.COL_NAME, width = 340, align = "LEFT" },
    }, BuildBlockedNPCSTData)
end

function VoiceOverTweaks:ShowSilencedLinesDialog()
    self:ShowTableDialog("SilencedLines", L.DIALOG_TITLE_SILENCED_LINES, {
        { name = L.COL_ID,   width = 70,  align = "LEFT", defaultsort = ScrollingTable.SORT_ASC, sort = ScrollingTable.SORT_ASC },
        { name = L.COL_NAME, width = 220, align = "LEFT" },
        { name = L.COL_LINE, width = 190, align = "LEFT" },
    }, BuildBlockedLineSTData)
end
