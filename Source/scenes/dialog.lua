-- path: Source/scenes/dialog.lua
import "CoreLibs/object"
import "CoreLibs/graphics"
import "systems/checks"

local gfx = playdate.graphics

--[[
Dialog scene with manual node IDs:
- All routing uses node.id as the source of truth.
- The script is still an array for sequential flow, but jump targets resolve via id map.
- After any dynamic insertion, the id map is rebuilt (inserted nodes normally have no id).
]]

class('Dialog').extends()

-- ===== Helpers for ID map =====

local function buildIdMap(script)
	-- Build a map id -> array index. Also validate uniqueness.
	local map = {}
	for idx, node in ipairs(script) do
		local id = node and node.id
		if id ~= nil then
			assert(type(id) == "number", "Dialog: node.id must be a number")
			assert(map[id] == nil, "Dialog: duplicate node.id=" .. tostring(id))
			map[id] = idx
		end
	end
	return map
end

local function formatTarget(v)
	if v == nil then return "nil" end
	return tostring(v)
end

local function sequenceHasExplicitRouting(seq)
	if not seq then return false end
	for _, n in ipairs(seq) do
		if n.target ~= nil then return true end
		if n.type == "jump" then return true end
	end
	return false
end

local function findLastRoutableIndex(seq)
	if not seq then return nil end
	for i = #seq, 1, -1 do
		local n = seq[i]
		if n and n.type ~= "midCheckLine" then
			return i
		end
	end
	return nil
end

-- ===== Class =====

function Dialog:init(arg1, script, stats, inventory)
	local cfg
	if type(arg1) == "table" then
		cfg            = arg1
		self.switch    = assert(cfg.switch, "Dialog: missing switch()")
		self.script    = assert(cfg.script, "Dialog: missing script table")
		self.stats     = cfg.stats or {}
		self.inventory = cfg.inventory or {}
	else
		self.switch    = assert(arg1, "Dialog: missing switch()")
		self.script    = assert(script, "Dialog: missing script table")
		self.stats     = stats or {}
		self.inventory = inventory or {}
	end

	-- Build initial id map
	self.idToPos = buildIdMap(self.script)

	-- State
	self.posIndex     = 1           -- array index of current node (not stable across inserts)
	self.currentId    = nil         -- stable id if node has one, else nil
	self.node         = nil
	self.choiceIndex  = 1
	self.choiceFirstVisible = 1

	-- typing effect
	self.currentText  = ""
	self.textPos      = 0
	self.typing       = false
	self.charInterval = 2
	self.frameCounter = 0

	-- Risk Dice UX
	self.mode          = nil      -- nil | "diceSelect" | "diceResult"
	self.riskDiceCount = 0
	self.testResult    = nil

	-- Checks instance
	self.checks = Checks()

	-- Start: prefer node with id=1 if present, else first element
	if self.idToPos[1] then
		self:enterById(1)
	else
		self:enterByPos(1)
	end
end

-- ===== Enter / Jump =====

function Dialog:rebuildIdMap()
	self.idToPos = buildIdMap(self.script)
end

function Dialog:enterByPos(pos)
	self.posIndex = pos
	self.node     = self.script[self.posIndex]
	self.currentId = (self.node and self.node.id) or nil

	-- reset UI states
	self.choiceIndex = 1
	self.choiceFirstVisible = 1
	self.mode          = nil
	self.riskDiceCount = 0
	self.testResult    = nil

	-- typing for text-like nodes
	if self.node then
		local t = self.node.type
		if t == "line" or t == "item" or t == "stat" or t == "midCheckLine" then
			self:prepareLine()
		else
			self.typing = false
		end
	end
	self:logNode()
end

function Dialog:enterById(id)
	local pos = self.idToPos[id]
	assert(pos, "Dialog: unknown node id=" .. tostring(id))
	self:enterByPos(pos)
end

function Dialog:jumpTo(targetId)
	assert(targetId ~= nil, "Dialog: jumpTo() missing target id")
	self:enterById(targetId)
end

function Dialog:advance()
	-- Sequential advance by array position (used when node has no explicit target)
	self:enterByPos(self.posIndex + 1)
end

-- ===== Typing =====

function Dialog:prepareLine()
	self.currentText  = self.node and (self.node.text or "") or ""
	self.textPos      = 0
	self.typing       = true
	self.frameCounter = 0
end

-- ===== Logging =====

function Dialog:logNode()
	if not self.node then
		print(string.format("[Dialog] enter pos=%d id=nil (nil node)", self.posIndex or -1))
		return
	end
	local t = tostring(self.node.type)
	local idStr = (self.node.id ~= nil) and tostring(self.node.id) or "nil"

	if t == "line" or t == "item" or t == "stat" or t == "midCheckLine" then
		local speaker = self.node.speaker or "-"
		local textPrev = (self.node.text and #self.node.text > 40) and (self.node.text:sub(1,37).."...") or (self.node.text or "")
		local targetStr = formatTarget(self.node.target)
		if t == "item" then
			local itemName = self.node.item or "-"
			print(string.format("[Dialog] enter pos=%d id=%s type=item item=%s speaker=%s target=%s text=\"%s\"",
				self.posIndex, idStr, itemName, speaker, targetStr, textPrev))
		elseif t == "stat" then
			local statName = self.node.stat or "-"
			local delta = tostring(self.node.delta or 0)
			print(string.format("[Dialog] enter pos=%d id=%s type=stat stat=%s delta=%s speaker=%s target=%s text=\"%s\"",
				self.posIndex, idStr, statName, delta, speaker, targetStr, textPrev))
		else
			print(string.format("[Dialog] enter pos=%d id=%s type=%s speaker=%s target=%s text=\"%s\"",
				self.posIndex, idStr, t, speaker, targetStr, textPrev))
		end
	elseif t == "choice" then
		local prompt = self.node.prompt or "-"
		local count  = (self.node.options and #self.node.options) or 0
		print(string.format("[Dialog] enter pos=%d id=%s type=choice prompt=\"%s\" options=%d",
			self.posIndex, idStr, prompt, count))
		if self.node.options then
			for i, opt in ipairs(self.node.options) do
				local ok = self:optionIsAvailable(opt)
				local lbl = opt.label or "-"
				local trg = formatTarget(opt.target)
				print(string.format("  [opt %d] %s target=%s [%s]", i, lbl, trg, ok and "OK" or "LOCK"))
			end
		end
	elseif t == "check" then
		local skill = self.node.skill or "?"
		local diff  = self.node.difficulty or 10
		local sT    = formatTarget(self.node.successTarget)
		local fT    = formatTarget(self.node.failTarget)
		print(string.format("[Dialog] enter pos=%d id=%s type=check skill=%s difficulty=%d successTarget=%s failTarget=%s",
			self.posIndex, idStr, skill, diff, sT, fT))
	else
		local trg = formatTarget(self.node.target)
		print(string.format("[Dialog] enter pos=%d id=%s type=%s target=%s", self.posIndex, idStr, t, trg))
	end
end

-- ===== Choice locks =====

function Dialog:optionIsAvailable(opt)
	if opt.requireStat then
		local need = opt.requireStat.value or 0
		local cur  = self.stats[opt.requireStat.name or ""] or 0
		if cur < need then return false end
	end
	if opt.requireItem then
		local have = false
		for _, item in ipairs(self.inventory) do
			if item == opt.requireItem then have = true break end
		end
		if not have then return false end
	end
	return true
end

-- ===== Update / Draw =====

function Dialog:update()
	gfx.clear(gfx.kColorWhite)

	if not self.node then
		gfx.drawTextAligned("(No node)", 192, 120, kTextAlignment.center)
		return
	end

	local nodeType = self.node.type

	-- Dynamic panel sizing
	local boxX, boxY, boxW, boxH = 16, 64, 384 - 32, 100
	if nodeType == "line" or nodeType == "item" or nodeType == "stat" or nodeType == "midCheckLine" then
		boxY, boxH = 64, 100
	elseif nodeType == "choice" then
		local count = (self.node.options and #self.node.options) or 0
		local wanted = 48 + (count * 20) + 16
		boxY = 48
		boxH = math.min(wanted, 140)
	elseif nodeType == "check" then
		if self.mode == "diceResult" then
			boxY, boxH = 40, 150
		else
			boxY, boxH = 56, 110
		end
	end

	-- Panel
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRoundRect(boxX, boxY, boxW, boxH, 8)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(boxX, boxY, boxW, boxH, 8)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)

	-- Content
	if nodeType == "line" or nodeType == "item" or nodeType == "stat" or nodeType == "midCheckLine" then
		-- typing
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
			local font = gfx.getFont()
			local fontHeight = (font and font:getHeight()) or 14
			local speakerY = math.max(0, boxY - fontHeight - 4)
			gfx.drawText(self.node.speaker .. ":", boxX + 8, speakerY)
		end
		gfx.drawTextInRect(textToDraw, boxX + 8, boxY + 8, boxW - 16, boxH - 16)
		gfx.drawTextAligned(self.typing and "* A skip * B menu" or "* A next * B menu", 192, 220, kTextAlignment.center)

	elseif nodeType == "choice" then
		gfx.drawTextInRect(self.node.prompt or "Choose:", boxX + 8, boxY + 8, boxW - 16, 40)

		local totalOptions = (self.node.options and #self.node.options) or 0
		local availableHeight = boxH - 56
		local maxVisibleOptions = math.max(1, math.floor(availableHeight / 20))

		local lastVisible = self.choiceFirstVisible + maxVisibleOptions - 1
		if self.choiceIndex < self.choiceFirstVisible then
			self.choiceFirstVisible = self.choiceIndex
		elseif self.choiceIndex > lastVisible then
			self.choiceFirstVisible = self.choiceIndex - maxVisibleOptions + 1
		end
		if totalOptions >= maxVisibleOptions then
			local maxStart = totalOptions - maxVisibleOptions + 1
			if self.choiceFirstVisible > maxStart then self.choiceFirstVisible = maxStart end
		else
			self.choiceFirstVisible = 1
		end
		if self.choiceFirstVisible < 1 then self.choiceFirstVisible = 1 end

		local drawFrom = self.choiceFirstVisible
		local drawTo = math.min(totalOptions, drawFrom + maxVisibleOptions - 1)
		local lineY = boxY + 48
		for i = drawFrom, drawTo do
			local option = self.node.options[i]
			local isAvailable = self:optionIsAvailable(option)
			local labelText = isAvailable and (option.label or "") or (option.lockedLabel or "???")
			if i == self.choiceIndex then
				gfx.fillRoundRect(boxX + 4, lineY - 2, boxW - 8, 18, 6)
				gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
				gfx.drawText(labelText, boxX + 10, lineY)
				gfx.setImageDrawMode(gfx.kDrawModeCopy)
			else
				gfx.drawText(labelText, boxX + 10, lineY)
			end
			lineY = lineY + 20
		end

		if self.choiceFirstVisible > 1 then
			gfx.fillTriangle(boxX + boxW - 16, boxY + 44, boxX + boxW - 8, boxY + 44, boxX + boxW - 12, boxY + 38)
		end
		if drawTo < totalOptions then
			gfx.fillTriangle(boxX + boxW - 16, boxY + boxH - 10, boxX + boxW - 8, boxY + boxH - 10, boxX + boxW - 12, boxY + boxH - 4)
		end

		gfx.drawTextAligned("* A confirm * B menu", 192, 220, kTextAlignment.center)

	elseif nodeType == "check" then
		local skillName       = self.node.skill or "?"
		local difficultyValue = self.node.difficulty or 1
		local baseStat        = self.stats[skillName] or 0
		local misfortune      = (self.checks and self.checks:getMisfortune()) or 0

		if self.mode == "diceSelect" then
			gfx.drawText(string.format("Select Risk Dice (0-2): %d", self.riskDiceCount), boxX + 8, boxY + 8)
			gfx.drawText(string.format("Misfortune: %d", misfortune), boxX + 8, boxY + 28)
			gfx.drawText("Use up/down to choose, A to roll, B to menu.", boxX + 8, boxY + 48)

		elseif self.mode == "diceResult" then
			local r = self.testResult
			if r then
				local y = boxY + 8
				local function drawDiceRow(label, values, markSuccess)
					gfx.drawText(label, boxX + 8, y)
					local x = boxX + 60
					for i, v in ipairs(values) do
						local dx = x + (i - 1) * 18
						if dx + 16 > boxX + boxW - 8 then break end
						if markSuccess and v >= 5 then
							gfx.fillRect(dx, y - 2, 16, 16)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							gfx.drawText(tostring(v), dx + 4, y)
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						else
							gfx.drawRect(dx, y - 2, 16, 16)
							gfx.drawText(tostring(v), dx + 4, y)
						end
					end
					y = y + 22
				end
				drawDiceRow("Raw:", r.rawRoll, false)
				drawDiceRow("Adjusted:", r.finalRoll, true)

				local resultTxt = string.format("Successes: %d/%d -> %s", r.successes, difficultyValue, r.passed and "success" or "fail")
				gfx.drawText(resultTxt, boxX + 8, y); y = y + 18

				local misText
				if self.riskDiceCount > 0 and not r.passed then
					misText = string.format("Misfortune: %d -> %d", r.misfortuneBefore, r.misfortuneAfter)
				else
					misText = string.format("Misfortune: %d", r.misfortuneBefore)
				end
				gfx.drawText(misText, boxX + 8, y)
			end
			gfx.drawTextAligned("* A continue * B menu", 192, 220, kTextAlignment.center)

		else
			local infoText = string.format("Test: %s vs %d (d6 + stat)", skillName, difficultyValue)
			local diceInfo = string.format("Dice: %d (stat) + Risk ? | Misfortune: %d", baseStat, misfortune)
			gfx.drawText(infoText, boxX + 8, boxY + 8)
			gfx.drawText(diceInfo, boxX + 8, boxY + 28)
			gfx.drawText("Press A to select Risk Dice, B to menu.", boxX + 8, boxY + 48)
			gfx.drawTextAligned("* A select * B menu", 192, 220, kTextAlignment.center)
		end

	else
		gfx.drawTextAligned("(Unknown node type)", 192, 120, kTextAlignment.center)
	end
end

-- ===== Input =====

function Dialog:up()
	if not self.node then return end
	local t = self.node.type
	if t == "choice" and self.mode == nil then
		local n = #self.node.options
		self.choiceIndex = ((self.choiceIndex - 2) % n) + 1
	elseif t == "check" and self.mode == "diceSelect" then
		self.riskDiceCount = math.max(0, self.riskDiceCount - 1)
	end
end

function Dialog:down()
	if not self.node then return end
	local t = self.node.type
	if t == "choice" and self.mode == nil then
		local n = #self.node.options
		self.choiceIndex = (self.choiceIndex % n) + 1
	elseif t == "check" and self.mode == "diceSelect" then
		self.riskDiceCount = math.min(2, self.riskDiceCount + 1)
	end
end

function Dialog:a()
	if not self.node then return end
	local t = self.node.type

	if t == "line" then
		if self.typing then
			self.textPos = #self.currentText
			self.typing = false
		else
			if self.node.target ~= nil then self:jumpTo(self.node.target) else self:advance() end
		end

	elseif t == "midCheckLine" then
		if self.typing then
			self.textPos = #self.currentText
			self.typing = false
		else
			self:advance()
		end

	elseif t == "item" then
		if self.typing then
			self.textPos = #self.currentText
			self.typing = false
		else
			if self.node.item then table.insert(self.inventory, self.node.item) end
			if self.node.target ~= nil then self:jumpTo(self.node.target) else self:advance() end
		end

	elseif t == "stat" then
		if self.typing then
			self.textPos = #self.currentText
			self.typing = false
		else
			local statName = assert(self.node.stat, "Dialog(stat): missing 'stat'")
			local delta = self.node.delta or 0
			local prev = self.stats[statName] or 0
			self.stats[statName] = prev + delta
			print(string.format("[Dialog] stat %s: %d -> %d", statName, prev, self.stats[statName]))
			if self.node.target ~= nil then self:jumpTo(self.node.target) else self:advance() end
		end

	elseif t == "choice" then
		local opt = self.node.options[self.choiceIndex]
		if opt then
			local ok = self:optionIsAvailable(opt)
			local trg = formatTarget(opt.target)
			local lbl = opt.label or "-"
			print(string.format("[Dialog] choose idx=%d label=\"%s\" target=%s [%s]",
				self.choiceIndex, lbl, trg, ok and "OK" or "LOCK"))
		end
		if opt and self:optionIsAvailable(opt) then
			if opt.target ~= nil then self:jumpTo(opt.target) else self:advance() end
		end

	elseif t == "check" then
		-- Stage 1: open selector
		if self.mode == nil then
			self.mode = "diceSelect"
			self.riskDiceCount = 0
			self.testResult = nil
			return
		end
		-- Stage 2: roll
		if self.mode == "diceSelect" then
			local skillName       = self.node.skill or "?"
			local difficultyValue = self.node.difficulty or 1
			local baseStat        = self.stats[skillName] or 0
			self.testResult = self.checks:performTest(baseStat, 0, difficultyValue, self.riskDiceCount)
			self.mode = "diceResult"
			return
		end
		-- Stage 3: inject summary + branch
		if self.mode == "diceResult" then
			local r = self.testResult
			if not r then
				self.mode = nil
				self.riskDiceCount = 0
				self:advance()
				return
			end
			local isSuccess       = r.passed
			local difficultyValue = self.node.difficulty or 1

			local rollInfoLine = {
				type = "midCheckLine",
				speaker = "Narrator",
				text = string.format(
					"Rolls: %s -> %s | Successes: %d/%d -> %s",
					table.concat(r.rawRoll, ", "),
					table.concat(r.finalRoll, ", "),
					r.successes, difficultyValue,
					isSuccess and "success" or "fail"
				)
			}

			local branchSeq = isSuccess and self.node.success or self.node.fail
			local defaultTarget = isSuccess and self.node.successTarget or self.node.failTarget

			local splice = {}
			table.insert(splice, rollInfoLine)
			if branchSeq then
				for _, el in ipairs(branchSeq) do table.insert(splice, el) end
			end
			if (not sequenceHasExplicitRouting(branchSeq)) and defaultTarget then
				local lastIdx = findLastRoutableIndex(branchSeq)
				if lastIdx then
					branchSeq[lastIdx].target = defaultTarget
				else
					rollInfoLine.type = "line"
					rollInfoLine.target = defaultTarget
				end
			end
			for off, el in ipairs(splice) do
				table.insert(self.script, self.posIndex + off, el)
			end

			-- Critical: dynamic insert shifts array positions; rebuild id map
			self:rebuildIdMap()

			self.mode = nil
			self.riskDiceCount = 0
			self.testResult = nil
			self:advance()
		end
	end
end

function Dialog:b()
	-- Cancel any dice UI and go to menu
	self.mode = nil
	self.riskDiceCount = 0
	self.testResult = nil
	self.switch("menu")
end
