import "CoreLibs/object"
import "systems/checks"
import "systems/combinator"

-- Holds all dialog state, routing and pure logic (no drawing).
class('DialogState').extends()

-- Helpers for id -> position map
local function buildIdMap(script)
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

local function formatTarget(v) return (v == nil) and "nil" or tostring(v) end

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

function DialogState:init(cfg)
	self.switch    = assert(cfg.switch, "DialogState: missing switch()")
	self.script    = assert(cfg.script, "DialogState: missing script")
	self.stats     = cfg.stats or {}
	self.inventory = cfg.inventory or {}
	self.combiner  = ItemCombiner()
	-- track selection for item combination
	self.firstSelectedId = nil

	self.idToPos = buildIdMap(self.script)

	-- Runtime node
	self.posIndex   = 1
	self.currentId  = nil
	self.node       = nil

	-- Choice state
	self.choiceIndex         = 1
	self.choiceFirstVisible  = 1

	-- Typing
	self.currentText  = ""
	self.textPos      = 0
	self.typing       = false
	self.charInterval = 2
	self.frameCounter = 0

	-- Checks
	self.mode          = nil    -- nil | "diceSelect" | "diceResult"
	self.riskDiceCount = 0
	self.testResult    = nil
	self.checks        = Checks()

	-- Tabs
	self.currentTab = "dialog"
	self.inventorySelectedIndex = 1

	-- Line scrolling (for long text)
	self.lineScrollY     = 0
	self.lineMaxScroll   = 0
	self.lineScrollStep  = 12 -- pixels per step when using Up/Down

	if self.idToPos[1] then
		self:enterById(1)
	else
		self:enterByPos(1)
	end
end

-- ===== Core transitions =====

function DialogState:rebuildIdMap()
	self.idToPos = buildIdMap(self.script)
end

function DialogState:enterByPos(pos)
	self.posIndex = pos
	self.node     = self.script[self.posIndex]
	self.currentId = (self.node and self.node.id) or nil

	-- reset per-node UI
	self.choiceIndex = 1
	self.choiceFirstVisible = 1
	self.mode          = nil
	self.riskDiceCount = 0
	self.testResult    = nil

	if self.node then
		local t = self.node.type
		if t == "line" or t == "item" or t == "stat" or t == "midCheckLine" then
			self:prepareLine()
		else
			self.typing = false
			-- also reset line scroll when leaving line-like nodes
			self.lineScrollY   = 0
			self.lineMaxScroll = 0
		end
	end
	self:logNode()
end

function DialogState:enterById(id)
	local pos = self.idToPos[id]
	assert(pos, "Dialog: unknown node id=" .. tostring(id))
	self:enterByPos(pos)
end

function DialogState:jumpTo(targetId)
	assert(targetId ~= nil, "Dialog: jumpTo() missing target id")
	self:enterById(targetId)
end

function DialogState:advance()
	self:enterByPos(self.posIndex + 1)
end

-- ===== Typing =====

function DialogState:prepareLine()
	self.currentText  = self.node and (self.node.text or "") or ""
	self.textPos      = 0
	self.typing       = true
	self.frameCounter = 0
	-- reset scroll for new text
	self.lineScrollY   = 0
	self.lineMaxScroll = 0
end

function DialogState:typingTick()
	if not self.typing then return end
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

function DialogState:typingSkip()
	self.textPos = #self.currentText
	self.typing  = false
end

-- ===== Line scrolling (long text) =====

-- Scroll by a number of "lines" (steps in pixels), negative for up, positive for down.
function DialogState:lineScroll(steps)
	local step = self.lineScrollStep or 12
	local maxS = math.max(0, self.lineMaxScroll or 0)
	self.lineScrollY = (self.lineScrollY or 0) + (steps * step)
	if self.lineScrollY < 0 then self.lineScrollY = 0 end
	if self.lineScrollY > maxS then self.lineScrollY = maxS end
end

function DialogState:lineScrollToBottom()
	self.lineScrollY = math.max(0, self.lineMaxScroll or 0)
end

-- ===== Logging =====

function DialogState:logNode()
	if not self.node then
		print(string.format("[Dialog] enter pos=%d id=nil (nil node)", self.posIndex or -1))
		return
	end
	local t = tostring(self.node.type)
	local idStr = (self.node.id ~= nil) and tostring(self.node.id) or "nil"

	if t == "line" or t == "item" or t == "stat" or t == "midCheckLine" then
		local speaker = self.node.speaker or "-"
		local textPrev = (self.node.text and #self.node.text > 40)
			and (self.node.text:sub(1,37).."...")
			or (self.node.text or "")
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

-- ===== Choice helpers =====

function DialogState:optionIsAvailable(opt)
	if opt.requireStat then
		local need = opt.requireStat.value or 0
		local cur  = self.stats[opt.requireStat.name or ""] or 0
		if cur < need then return false end
	end
	if opt.requireItem then
		-- Support either Inventory object (:has) or raw list
		if type(self.inventory) == "table" and self.inventory.has and type(self.inventory.has) == "function" then
			if not self.inventory:has(opt.requireItem) then return false end
		else
			local have = false
			for _, id in ipairs(self.inventory) do
				if id == opt.requireItem then have = true break end
			end
			if not have then return false end
		end
	end
	return true
end

function DialogState:choicePrev()
	local n = (self.node.options and #self.node.options) or 0
	if n > 0 then self.choiceIndex = ((self.choiceIndex - 2) % n) + 1 end
end

function DialogState:choiceNext()
	local n = (self.node.options and #self.node.options) or 0
	if n > 0 then self.choiceIndex = (self.choiceIndex % n) + 1 end
end

function DialogState:executeChoice()
	local opt = self.node.options and self.node.options[self.choiceIndex]
	if not opt then return end
	local ok = self:optionIsAvailable(opt)
	local trg = formatTarget(opt.target)
	local lbl = opt.label or "-"
	print(string.format("[Dialog] choose idx=%d label=\"%s\" target=%s [%s]",
		self.choiceIndex, lbl, trg, ok and "OK" or "LOCK"))
	if ok then
		if opt.target ~= nil then self:jumpTo(opt.target) else self:advance() end
	end
end

-- ===== Check helpers =====

function DialogState:increaseRisk()
	self.riskDiceCount = math.min(2, (self.riskDiceCount or 0) + 1)
end

function DialogState:decreaseRisk()
	self.riskDiceCount = math.max(0, (self.riskDiceCount or 0) - 1)
end

function DialogState:resetCheckUI()
	self.mode = nil
	self.riskDiceCount = 0
	self.testResult = nil
end

function DialogState:checkAdvanceStages()
	if self.mode == nil then
		self.mode = "diceSelect"
		self.riskDiceCount = 0
		self.testResult = nil
		return
	end
	if self.mode == "diceSelect" then
		local skillName       = self.node.skill or "?"
		local difficultyValue = self.node.difficulty or 1
		local baseStat        = self.stats[skillName] or 0
		self.testResult = self.checks:performTest(baseStat, 0, difficultyValue, self.riskDiceCount)
		self.mode = "diceResult"
		return
	end
	if self.mode == "diceResult" then
		local r = self.testResult
		if not r then
			self:resetCheckUI()
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
		if branchSeq then for _, el in ipairs(branchSeq) do table.insert(splice, el) end end

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
		self:rebuildIdMap()

		self:resetCheckUI()
		self:advance()
	end
end

-- ===== Inventory helpers =====

function DialogState:giveItemIfAny()
	if not (self.node and self.node.item) then return end
	local id = self.node.item
	if type(self.inventory) == "table" and self.inventory.add and type(self.inventory.add) == "function" then
		self.inventory:add(id)
	else
		table.insert(self.inventory, id)
	end
end

function DialogState:inventoryIds()
	if type(self.inventory) == "table" and self.inventory.getAll and type(self.inventory.getAll) == "function" then
		return self.inventory:getAll()
	elseif type(self.inventory) == "table" then
		local copy = {}
		for i, v in ipairs(self.inventory) do copy[i] = v end
		return copy
	end
	return {}
end

function DialogState:itemInfoById(id)
	if type(self.inventory) == "table" and self.inventory.get and type(self.inventory.get) == "function" then
		return self.inventory:get(id)
	end
	return nil
end

function DialogState:inventorySelectPrev()
	local ids = self:inventoryIds()
	local count = #ids
	if count == 0 then self.inventorySelectedIndex = 1 return end
	if not self.inventorySelectedIndex then self.inventorySelectedIndex = 1 return end
	if self.inventorySelectedIndex > 1 then self.inventorySelectedIndex -= 1 end
end

function DialogState:inventorySelectNext()
	local ids = self:inventoryIds()
	local count = #ids
	if count == 0 then self.inventorySelectedIndex = 1 return end
	if not self.inventorySelectedIndex then self.inventorySelectedIndex = 1 return end
	if self.inventorySelectedIndex < count then self.inventorySelectedIndex += 1 end
end

-- Handle the A button when in the inventory tab.
-- First press selects an item; second press attempts combination.
function DialogState:inventoryHandleConfirm()
	local ids = self:inventoryIds()
	local idx = self.inventorySelectedIndex or 1
	local currentId = ids[idx]
	if not currentId then return end

	if not self.firstSelectedId then
		self.firstSelectedId = currentId
		print("[Combine] Selected '" .. currentId .. "'")
		return
	end

	if self.firstSelectedId == currentId then
		print("[Combine] Cannot combine item with itself")
		self.firstSelectedId = nil
		return
	end

	local resultId = self.combiner and self.combiner:attemptCombine(self.inventory, self.firstSelectedId, currentId) or nil
	if resultId then
		print(string.format("[Combine] %s + %s -> %s", self.firstSelectedId, currentId, resultId))
		-- Optional: move cursor to the newly added result, so renderer shows its proper name/description from items_01
		local all = self:inventoryIds()
		for i = 1, #all do
			if all[i] == resultId then
				self.inventorySelectedIndex = i
				break
			end
		end
	else
		print("[Combine] These items cannot be combined")
	end

	self.firstSelectedId = nil
end

-- Optional: cancel helper for B in inventory
function DialogState:inventoryCancel()
	if self.firstSelectedId then
		self.firstSelectedId = nil
		print("[Combine] Selection cleared")
		return true
	end
	return false
end

-- ===== Small helpers =====

function DialogState:routeOrAdvance()
	if self.node and self.node.target ~= nil then
		self:jumpTo(self.node.target)
	else
		self:advance()
	end
end

-- Reset lock UI state when entering a lock node.
function DialogState:resetLockUIFromNode()
	self.lockSlotIndex = 1
	local node = self.node or {}
	local slotCount = node.slots or ((node.solution and #node.solution) or 3)
	self.lockValues = {}
	local initialValues = node.initial or {}
	for i = 1, slotCount do
		self.lockValues[i] = initialValues[i] or 1
	end
end

-- Move selection to the previous dial
function DialogState:lockSlotPrev()
	if not (self.node and self.node.type == "lock") then return end
	local slots = self.node.slots or ((self.node.solution and #self.node.solution) or 3)
	local idx = (self.lockSlotIndex or 1) - 1
	if idx < 1 then
		idx = slots
	end
	self.lockSlotIndex = idx
end

-- Move selection to the next dial
function DialogState:lockSlotNext()
	if not (self.node and self.node.type == "lock") then return end
	local slots = self.node.slots or ((self.node.solution and #self.node.solution) or 3)
	local idx = (self.lockSlotIndex or 1) + 1
	if idx > slots then
		idx = 1
	end
	self.lockSlotIndex = idx
end

-- Rotate the current dial forward.
function DialogState:lockValueNext()
	if not (self.node and self.node.type == "lock") then
		return
	end
	if self.lockValues == nil then
		self:resetLockUIFromNode()
	end
	if self.lockValues == nil then
		self:resetLockUIFromNode()
	end
	local symbolCount = (self.node.symbols and #self.node.symbols) or 10
	local index = self.lockSlotIndex or 1
	local value = (self.lockValues[index] or 1) + 1
	if value > symbolCount then
		value = 1
	end
	self.lockValues[index] = value
end

-- Rotate the current dial backward.
function DialogState:lockValuePrev()
	if not (self.node and self.node.type == "lock") then
		return
	end
	if self.lockValues == nil then
		self:resetLockUIFromNode()
	end
	if self.lockValues == nil then
		self:resetLockUIFromNode()
	end
	local symbolCount = (self.node.symbols and #self.node.symbols) or 10
	local index = self.lockSlotIndex or 1
	local value = (self.lockValues[index] or 1) - 1
	if value < 1 then
		value = symbolCount
	end
	self.lockValues[index] = value
end

-- Move to the next dial or confirm on the last dial.
function DialogState:lockAdvanceOrConfirm()
	if not (self.node and self.node.type == "lock") then
		return
	end
	local slotCount = self.node.slots or ((self.node.solution and #self.node.solution) or 3)
	if (self.lockSlotIndex or 1) < slotCount then
		self.lockSlotIndex = (self.lockSlotIndex or 1) + 1
	else
		self:lockConfirm()
	end
end

-- Validate the entered combination and branch accordingly.
function DialogState:lockConfirm()
	if self.lockValues == nil then
		if self.node and self.node.type == "lock" then
			self:resetLockUIFromNode()
		else
			self.lockValues = {}
		end
	end
	local node = self.node or {}
	local symbols = node.symbols or { "0","1","2","3","4","5","6","7","8","9" }
	local solution = node.solution or {}
	local slotCount = node.slots or (#solution > 0 and #solution or 3)

	-- Check if entered values match the solution.
	local success = true
	for i = 1, slotCount do
		local expected = solution[i]
		local currentIndex = self.lockValues[i] or 1
		if type(expected) == "number" then
			if currentIndex ~= expected then
				success = false
				break
			end
		else
			local currentLabel = symbols[currentIndex]
			if currentLabel ~= expected then
				success = false
				break
			end
		end
	end

	local infoText = success
		and (node.successText or "The lock clicks and opens.")
		or (node.failText or "The mechanism resets itself.")
	local infoLine = { type = "line", speaker = "Narrator", text = infoText }
	local branchSequence = success and node.success or node.fail
	local defaultTarget = success and node.successTarget or node.failTarget

	-- Insert the informational line and the branch sequence into the script.
	local splice = {}
	table.insert(splice, infoLine)
	if branchSequence ~= nil then
		for _, element in ipairs(branchSequence) do
			table.insert(splice, element)
		end
	end

	-- Determine whether the branch contains explicit routing.
	local function sequenceHasRouting(seq)
		if seq == nil then return false end
		for _, item in ipairs(seq) do
			if item.target then
				return true
			end
		end
		return false
	end

	-- Attach default routing when no explicit target is provided.
	if not sequenceHasRouting(branchSequence) and defaultTarget ~= nil then
		local lastIndex = findLastRoutableIndex(branchSequence)
		if lastIndex ~= nil then
			branchSequence[lastIndex].target = defaultTarget
		else
			infoLine.target = defaultTarget
		end
	end

	-- Splice the new sequence into the script and rebuild id map.
	for offset, element in ipairs(splice) do
		table.insert(self.script, self.posIndex + offset, element)
	end
	self:rebuildIdMap()

	-- Prepare for the next use.
	self:resetLockUIFromNode()
	self:advance()
end
