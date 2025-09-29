import "CoreLibs/object"
import "CoreLibs/graphics"
import "scenes/dialog/panels/line_panel"
import "scenes/dialog/panels/choice_panel"
import "scenes/dialog/panels/check_panel"
-- We keep the inventory panel import for parity (not used for drawing here).
import "scenes/dialog/panels/inventory_panel"
-- Fallback for item info lookup if state does not provide it:
import "data/items_01"

local gfx = playdate.graphics

class('DialogRenderer').extends()

-- Baseline panel layout used by all panels to align tabs
local PANEL_X  <const> = 16
local PANEL_Y  <const> = 40
local PANEL_W  <const> = 384 - 32
local PANEL_H  <const> = 140

local function drawAttachedTabs(anchorX, anchorY, anchorW, active)
	local tabGap     = 4
	local tabWidth   = 96
	local tabHeight  = 22
	local radius     = 6

	local dialogX  = anchorX + 8
	local invX     = dialogX + tabWidth + tabGap
	local tabTopY  = anchorY - 1
	local textY    = tabTopY + 5

	local function drawTab(x, label, isActive)
		if isActive then
			gfx.fillRoundRect(x, tabTopY, tabWidth, tabHeight, radius)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			gfx.drawTextAligned(label, x + tabWidth / 2, textY, kTextAlignment.center)
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
			gfx.setColor(gfx.kColorWhite)
			gfx.fillRect(x + 1, tabTopY - 2, tabWidth - 2, 3)
			gfx.setColor(gfx.kColorBlack)
		else
			gfx.drawRoundRect(x, tabTopY, tabWidth, tabHeight, radius)
			gfx.drawTextAligned(label, x + tabWidth / 2, textY, kTextAlignment.center)
		end
	end

	drawTab(dialogX, "Dialog",    active == "dialog")
	drawTab(invX,    "Inventory", active == "inventory")
end

function DialogRenderer:init(state)
	self.state = state
end

-- ===== Utils =====

local function clampInt(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

-- Compute a visible window so the selected index stays on screen.
local function computeWindow(selected, total, maxVisible)
	if total <= maxVisible then
		return 1, total
	end
	local half = math.floor((maxVisible - 1) / 2)
	local start = selected - half
	if start < 1 then start = 1 end
	local maxStart = math.max(1, total - maxVisible + 1)
	if start > maxStart then start = maxStart end
	return start, math.min(total, start + maxVisible - 1)
end

-- Try to get item info from state, then fall back to ITEMS_01 (imported).
local function resolveItemInfo(state, itemId)
	if not itemId then return nil end
	-- Preferred: a helper on state (if implemented)
	if state.itemInfoById and type(state.itemInfoById) == "function" then
		local info = state:itemInfoById(itemId)
		if info then return info end
	end
	-- Fallback to ITEMS_01 table
	if ITEMS_01 and ITEMS_01[itemId] then
		return ITEMS_01[itemId]
	end
	-- Last resort: synthesize minimal info
	return { id = itemId, name = tostring(itemId), description = "" }
end

-- ===== Inventory Tab Rendering =====

local function drawInventoryPanel(state, boxX, boxY, boxW, boxH)
	-- Panel background
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRoundRect(boxX, boxY, boxW, boxH, 8)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(boxX, boxY, boxW, boxH, 8)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)

	-- Header: show selected-for-combine if any
	local header = state.firstSelectedId
		and ("Inventory (selected: " .. tostring(state.firstSelectedId) .. ")")
		or  "Inventory (press A to select/combine)"
	gfx.drawTextInRect(header, boxX + 8, boxY + 8, boxW - 16, 16)

	-- Geometry
	local ids           = state:inventoryIds()
	local count         = #ids
	local listTopY      = boxY + 32
	local rowH          = 18
	local padX          = 4
	local textOffX      = 10
	-- Reserve a description box at the bottom of the panel
	local descMarginTop = 8
	local descH         = 44              -- height for item name + few lines of text
	local descY         = boxY + boxH - descH - 8
	-- List area ends before the description box
	local listBottomY   = descY - descMarginTop
	local listHeight    = math.max(0, listBottomY - listTopY)
	local maxVisible    = math.max(1, math.floor(listHeight / rowH))

	-- Selected index and window
	local selectedIdx   = clampInt(state.inventorySelectedIndex or 1, 1, math.max(1, count))
	local fromIdx, toIdx = computeWindow(selectedIdx, count, maxVisible)

	-- Draw list rows
	for i = fromIdx, toIdx do
		local itemId          = ids[i]
		local isCursor        = (i == selectedIdx)
		local isFirstSelected = (state.firstSelectedId == itemId)

		-- Reset per-row draw state
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		playdate.graphics.setDitherPattern(1.0, gfx.image.kDitherTypeBayer8x8)
		gfx.setColor(gfx.kColorBlack)

		local rowY = listTopY + (i - fromIdx) * rowH

		-- 1) Solid cursor background with inverted text
		if isCursor then
			gfx.fillRoundRect(boxX + padX, rowY - 2, boxW - 2 * padX, rowH, 6)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		end

		-- 2) Dither overlay for "first selected" (combine source)
		if isFirstSelected then
			local inset = isCursor and 2 or 0
			playdate.graphics.setDitherPattern(0.5, gfx.image.kDitherTypeBayer8x8)
			gfx.fillRoundRect(boxX + padX + inset, rowY - 2 + inset, (boxW - 2 * padX) - inset * 2, rowH - inset * 2, 6)
			playdate.graphics.setDitherPattern(1.0, gfx.image.kDitherTypeBayer8x8)
		end

		-- 3) Label
		gfx.drawText(tostring(itemId or "-"), boxX + textOffX, rowY)

		-- Ensure clean state for next row
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end

	-- Draw description box
	-- Panel
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRoundRect(boxX + 6, descY, boxW - 12, descH, 6)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(boxX + 6, descY, boxW - 12, descH, 6)

	-- Resolve selected item info (name + description)
	local selectedId   = (count > 0) and ids[selectedIdx] or nil
	local info         = resolveItemInfo(state, selectedId)
	local nameText     = info and info.name or (selectedId or "")
	local descText     = info and info.description or ""

	-- Draw name (single line) and wrapped description
	local nameY = descY + 6
	local textX = boxX + 12
	gfx.drawText(tostring(nameText or ""), textX, nameY)

	local wrapY = nameY + 16
	local wrapH = descY + descH - wrapY - 6
	if wrapH > 0 then
		gfx.drawTextInRect(tostring(descText or ""), textX, wrapY, (boxW - 24), wrapH)
	end

	-- Footer: show combine hint or cancel
	local footer = state.firstSelectedId and "* A combine with this * B cancel"
									   or  "* A select/combine * B back"
	gfx.drawTextAligned(footer, 192, 220, kTextAlignment.center)
end

-- ===== Dialog Tab =====

function DialogRenderer:_dialogPanelBox(nodeType)
	local boxX, boxY, boxW, boxH = 16, 64, 384 - 32, 100
	if nodeType == "line" or nodeType == "item" or nodeType == "stat" or nodeType == "midCheckLine" then
		boxY, boxH = 64, 100
	elseif nodeType == "choice" then
		local count = (self.state.node.options and #self.state.node.options) or 0
		local wanted = 48 + (count * 20) + 16
		boxY = 48
		boxH = math.min(wanted, 140)
	elseif nodeType == "check" then
		if self.state.mode == "diceResult" then
			boxY, boxH = 40, 150
		else
			boxY, boxH = 56, 110
		end
	end
	return boxX, boxY, boxW, boxH
end

function DialogRenderer:drawFrame()
	gfx.clear(gfx.kColorWhite)

	local node = self.state.node
	local nodeType = node and node.type or nil

	local boxX, boxY, boxW, boxH

	if self.state.currentTab == "inventory" then
		boxX, boxY, boxW, boxH = PANEL_X, PANEL_Y, PANEL_W, PANEL_H
		drawInventoryPanel(self.state, boxX, boxY, boxW, boxH)
		drawAttachedTabs(boxX, boxY + boxH, boxW, self.state.currentTab)
		return
	end

	if not node then
		gfx.drawTextAligned("(No node)", 192, 120, kTextAlignment.center)
		boxX, boxY, boxW, boxH = PANEL_X, PANEL_Y, PANEL_W, PANEL_H
		drawAttachedTabs(boxX, boxY + boxH, boxW, self.state.currentTab)
		return
	end

	boxX, boxY, boxW, boxH = self:_dialogPanelBox(nodeType)

	-- Panel background
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRoundRect(boxX, boxY, boxW, boxH, 8)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(boxX, boxY, boxW, boxH, 8)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)

	-- Delegate to specific panel
	if nodeType == "line" or nodeType == "item" or nodeType == "stat" or nodeType == "midCheckLine" then
		self.state:typingTick()
		LinePanel.draw(self.state, boxX, boxY, boxW, boxH)

	elseif nodeType == "choice" then
		ChoicePanel.draw(self.state, boxX, boxY, boxW, boxH)

	elseif nodeType == "check" then
		CheckPanel.draw(self.state, boxX, boxY, boxW, boxH)

	else
		gfx.drawTextAligned("(Unknown node type)", 192, 120, kTextAlignment.center)
	end

	-- Tabs
	drawAttachedTabs(boxX, boxY + boxH, boxW, self.state.currentTab)
end
