-- path: scenes/dialog.lua
import "CoreLibs/object"
import "CoreLibs/graphics"

local gfx = playdate.graphics

--[[
Dialog scene with:
- text box frame
- typing effect for lines
- conditional choices (requireStat / requireItem)
- item nodes (type = "item") that add items to inventory
- stat nodes (type = "stat") that modify character stats
- one-time logging on node enter
- midCheckLine: informational line used inside check branches (ignores target, always advances)
]]

class('Dialog').extends()

-- Accept both config-table and positional args for backward compatibility.
function Dialog:init(arg1, script, stats, inventory)
	local configTable
	if type(arg1) == "table" then
		configTable     = arg1
		self.switch     = assert(configTable.switch, "Dialog: missing switch()")
		self.script     = assert(configTable.script, "Dialog: missing script table")
		self.stats      = configTable.stats or {}
		self.inventory  = configTable.inventory or {}
	else
		-- positional: (switchFn, script, stats?, inventory?)
		self.switch     = assert(arg1, "Dialog: missing switch()")
		self.script     = assert(script, "Dialog: missing script table")
		self.stats      = stats or {}
		self.inventory  = inventory or {}
	end

	self.index             = 1
	self.choiceIndex       = 1
	self.node              = nil

	-- typing effect state
	self.currentText       = ""
	self.textPos           = 0
	self.typing            = false
	self.charInterval      = 2       -- frames per character
	self.frameCounter      = 0

	-- enter first node (logs once)
	self:enterNode(1)
end

-- Prepare the typing effect for current line-like node
function Dialog:prepareLine()
	self.currentText  = self.node and (self.node.text or "") or ""
	self.textPos      = 0
	self.typing       = true
	self.frameCounter = 0
end

-- helper: stringify target
local function formatTarget(targetValue)
	if targetValue == nil then return "nil" end
	return tostring(targetValue)
end

-- Detect explicit routing inside a sequence (e.g., success/fail arrays)
local function sequenceHasExplicitRouting(sequence)
	if not sequence then return false end
	for _, nodeElement in ipairs(sequence) do
		if nodeElement.target ~= nil then return true end
		if nodeElement.type == "jump" then return true end -- allow legacy scripts
	end
	return false
end

-- Find last node in sequence that is allowed to carry a target (not midCheckLine)
local function findLastRoutableIndex(sequence)
	if not sequence then return nil end
	for reverseIndex = #sequence, 1, -1 do
		local nodeElement = sequence[reverseIndex]
		if nodeElement and nodeElement.type ~= "midCheckLine" then
			return reverseIndex
		end
	end
	return nil
end

-- Log current node once (called only when entering a node)
function Dialog:logNode()
	if not self.node then
		print(string.format("[Dialog] enter node #%d (nil)", self.index or -1))
		return
	end

	local nodeType = tostring(self.node.type)
	if nodeType == "line" or nodeType == "item" or nodeType == "stat" or nodeType == "midCheckLine" then
		local speakerName = self.node.speaker or "-"
		local textPreview = (self.node.text and #self.node.text > 40) and (self.node.text:sub(1, 37) .. "...") or (self.node.text or "")
		local targetString = formatTarget(self.node.target)
		if nodeType == "item" then
			local itemName = self.node.item or "-"
			print(string.format("[Dialog] enter node #%d type=item item=%s speaker=%s target=%s text=\"%s\"",
				self.index, itemName, speakerName, targetString, textPreview))
		elseif nodeType == "stat" then
			local statName = self.node.stat or "-"
			local statDelta = tostring(self.node.delta or 0)
			print(string.format("[Dialog] enter node #%d type=stat stat=%s delta=%s speaker=%s target=%s text=\"%s\"",
				self.index, statName, statDelta, speakerName, targetString, textPreview))
		else
			print(string.format("[Dialog] enter node #%d type=%s speaker=%s target=%s text=\"%s\"",
				self.index, nodeType, speakerName, targetString, textPreview))
		end

	elseif nodeType == "choice" then
		local promptText   = self.node.prompt or "-"
		local optionsCount = (self.node.options and #self.node.options) or 0
		print(string.format("[Dialog] enter node #%d type=choice prompt=\"%s\" options=%d",
			self.index, promptText, optionsCount))
		if self.node.options then
			for optionIndex, option in ipairs(self.node.options) do
				local isAvailable  = self:optionIsAvailable(option)
				local optionLabel  = option.label or "-"
				local optionTarget = formatTarget(option.target)
				local lockMark     = isAvailable and "OK" or "LOCK"
				print(string.format("  [opt %d] %s target=%s [%s]", optionIndex, optionLabel, optionTarget, lockMark))
			end
		end

	elseif nodeType == "check" then
		local skillName         = self.node.skill or "?"
		local difficultyValue   = self.node.difficulty or 10
		local successTargetText = formatTarget(self.node.successTarget)
		local failTargetText    = formatTarget(self.node.failTarget)
		print(string.format("[Dialog] enter node #%d type=check skill=%s difficulty=%d successTarget=%s failTarget=%s",
			self.index, skillName, difficultyValue, successTargetText, failTargetText))

	else
		local targetString = formatTarget(self.node.target)
		print(string.format("[Dialog] enter node #%d type=%s target=%s", self.index, nodeType, targetString))
	end
end


-- Enter a specific node index: sets node, prepares typing, logs once
function Dialog:enterNode(targetIndex)
	self.index       = targetIndex
	self.choiceIndex = 1
	self.node        = self.script[self.index]

	if self.node then
		local nodeType = self.node.type
		if nodeType == "line" or nodeType == "item" or nodeType == "stat" or nodeType == "midCheckLine" then
			self:prepareLine()
		else
			-- no typing for non-line-like nodes
			self.typing = false
		end
	end

	-- one-time log
	self:logNode()
end

-- Jump to a specific node index
function Dialog:jumpTo(targetIndex)
	self:enterNode(targetIndex)
end

-- Advance to the next node
function Dialog:advance()
	self:enterNode(self.index + 1)
end

-- Check if a choice option can be selected given stats and inventory
function Dialog:optionIsAvailable(option)
	if option.requireStat then
		local requiredValue  = option.requireStat.value or 0
		local requiredName   = option.requireStat.name or "?"
		local currentValue   = self.stats[requiredName] or 0
		if currentValue < requiredValue then return false end
	end
	if option.requireItem then
		local requiredItemName = option.requireItem
		local hasRequiredItem  = false
		for _, inventoryItemName in ipairs(self.inventory) do
			if inventoryItemName == requiredItemName then
				hasRequiredItem = true
				break
			end
		end
		if not hasRequiredItem then return false end
	end
	return true
end

-- Render
function Dialog:update()
	-- header
	gfx.clear(gfx.kColorWhite)
	gfx.fillRoundRect(8, 8, 384 - 16, 24, 8)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	gfx.drawTextInRect("Dialog", 14, 12, 384 - 28, 20)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)

	-- text frame
	local boxX, boxY, boxW, boxH = 8, 40, 384 - 16, 160
	gfx.drawRoundRect(boxX, boxY, boxW, boxH, 8)

	if not self.node then
		gfx.drawTextAligned("(End of dialog) - B to menu", 192, 120, kTextAlignment.center)
		return
	end

	local nodeType = self.node.type

	if nodeType == "line" or nodeType == "item" or nodeType == "stat" or nodeType == "midCheckLine" then
		-- typing effect
		if self.typing then
			self.frameCounter += 1
			if self.frameCounter >= self.charInterval then
				self.frameCounter = 0
				if self.textPos < #self.currentText then
					self.textPos += 1
				else
					self.typing = false
				end
			end
		end
		local textToDraw = self.currentText:sub(1, self.textPos)
		if self.node.speaker then
			gfx.drawText(self.node.speaker .. ":", boxX + 8, boxY - 12)
		end
		gfx.drawTextInRect(textToDraw, boxX + 8, boxY + 8, boxW - 16, boxH - 16)
		if self.typing then
			gfx.drawTextAligned("* A skip * B menu", 192, 220, kTextAlignment.center)
		else
			gfx.drawTextAligned("* A next * B menu", 192, 220, kTextAlignment.center)
		end

	elseif nodeType == "choice" then
		gfx.drawTextInRect(self.node.prompt or "Choose:", boxX + 8, boxY + 8, boxW - 16, 40)
		for optionIndex, option in ipairs(self.node.options) do
			local optionY = boxY + 48 + (optionIndex - 1) * 20
			local isAvailable = self:optionIsAvailable(option)
			local labelText = isAvailable and option.label or (option.lockedLabel or "???")
			if optionIndex == self.choiceIndex then
				gfx.fillRoundRect(boxX + 4, optionY - 2, boxW - 8, 18, 6)
				gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
				gfx.drawText(labelText, boxX + 10, optionY)
				gfx.setImageDrawMode(gfx.kDrawModeCopy)
			else
				gfx.drawText(labelText, boxX + 10, optionY)
			end
		end
		gfx.drawTextAligned("* A confirm * B menu", 192, 220, kTextAlignment.center)

	elseif nodeType == "check" then
		local infoText = string.format("Check: %s vs %d (d20 + stat)", self.node.skill or "?", self.node.difficulty or 10)
		gfx.drawText(infoText, boxX + 8, boxY + 8)
		gfx.drawText("Press A to roll. B to menu.", boxX + 8, boxY + 28)

	else
		gfx.drawTextAligned("(Unknown node type)", 192, 120, kTextAlignment.center)
	end
end

-- Input
function Dialog:up()
	if self.node and self.node.type == "choice" then
		local optionsCount = #self.node.options
		self.choiceIndex = ((self.choiceIndex - 2) % optionsCount) + 1
	end
end

function Dialog:down()
	if self.node and self.node.type == "choice" then
		local optionsCount = #self.node.options
		self.choiceIndex = (self.choiceIndex % optionsCount) + 1
	end
end

function Dialog:a()
	if not self.node then return end
	local nodeType = self.node.type

	if nodeType == "line" then
		if self.typing then
			self.textPos = #self.currentText
			self.typing = false
		else
			-- Respect optional target on line; fallback to next
			if self.node.target then
				self:jumpTo(self.node.target)
			else
				self:advance()
			end
		end

	elseif nodeType == "midCheckLine" then
		-- midCheckLine ignores target and always goes to next
		if self.typing then
			self.textPos = #self.currentText
			self.typing = false
		else
			self:advance()
		end

	elseif nodeType == "item" then
		if self.typing then
			self.textPos = #self.currentText
			self.typing = false
		else
			if self.node.item then
				table.insert(self.inventory, self.node.item)
			end
			-- Respect optional target on item; fallback to next
			if self.node.target then
				self:jumpTo(self.node.target)
			else
				self:advance()
			end
		end

	elseif nodeType == "stat" then
		-- Apply stat modification after text is fully shown
		if self.typing then
			self.textPos = #self.currentText
			self.typing = false
		else
			local statName = assert(self.node.stat, "Dialog(stat): missing 'stat' field")
			local statDelta = self.node.delta or 0
			local previousValue = self.stats[statName] or 0
			self.stats[statName] = previousValue + statDelta
			print(string.format("[Dialog] stat %s: %d -> %d", statName, previousValue, self.stats[statName]))

			-- Respect optional target on stat; fallback to next
			if self.node.target then
				self:jumpTo(self.node.target)
			else
				self:advance()
			end
		end

	elseif nodeType == "choice" then
		local selectedOption = self.node.options[self.choiceIndex]
		if selectedOption then
			local isAvailable = self:optionIsAvailable(selectedOption)
			local targetString = formatTarget(selectedOption.target)
			local optionLabel = selectedOption.label or "-"
			print(string.format("[Dialog] choose idx=%d label=\"%s\" target=%s [%s]",
				self.choiceIndex, optionLabel, targetString, isAvailable and "OK" or "LOCK"))
		end
		if selectedOption and self:optionIsAvailable(selectedOption) then
			if selectedOption.target then
				self:jumpTo(selectedOption.target)
			else
				self:advance()
			end
		else
			-- optional feedback for locked choice
		end

	elseif nodeType == "check" then
		local skillName       = self.node.skill or "Speech"
		local difficultyValue = self.node.difficulty or 10
		local baseStat        = self.stats[skillName] or 0
		local rollValue       = math.random(1, 20)
		local totalValue      = rollValue + baseStat
		local isSuccess       = (totalValue >= difficultyValue)

		-- Build a roll info line. We prefer midCheckLine (no routing),
		-- but may switch it to a routable line later if needed.
		local rollInfoLine = {
			type = "midCheckLine",
			speaker = "Narrator",
			text = string.format(
				"Roll: %d + %s(%d) = %d vs %d -> %s",
				rollValue, skillName, baseStat, totalValue, difficultyValue, isSuccess and "success" or "fail"
			)
		}

		local branchSequence = isSuccess and self.node.success or self.node.fail
		local defaultBranchTarget = isSuccess and self.node.successTarget or self.node.failTarget

		-- Prepare a splice buffer
		local spliceBuffer = {}
		table.insert(spliceBuffer, rollInfoLine)

		-- Inject user-provided branch as-is
		if branchSequence then
			for _, nodeElement in ipairs(branchSequence) do
				table.insert(spliceBuffer, nodeElement)
			end
		end

		-- If branch has no explicit routing, and a default target is provided on check,
		-- attach that target to the last routable node. If none exists, convert the
		-- roll line into a routable line and attach target there.
		if (not sequenceHasExplicitRouting(branchSequence)) and defaultBranchTarget then
			local lastRoutableIndex = findLastRoutableIndex(branchSequence)
			if lastRoutableIndex then
				branchSequence[lastRoutableIndex].target = defaultBranchTarget
			else
				rollInfoLine.type = "line"
				rollInfoLine.target = defaultBranchTarget
			end
		end

		-- Splice the prepared nodes right after current node
		for insertOffset, nodeElement in ipairs(spliceBuffer) do
			table.insert(self.script, self.index + insertOffset, nodeElement)
		end

		-- Move to the first injected node
		self:advance()
	end
end

function Dialog:b()
	self.switch("menu")
end
