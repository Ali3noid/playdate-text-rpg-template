import "CoreLibs/object"
import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

class('Dialog').extends()

function Dialog:init(config)
	self.switch = assert(config and config.switch, "Dialog: missing switch()")
	self.script = assert(config and config.script, "Dialog: missing script table")
	-- optional player stats; defaults for prototype
	self.stats  = config.stats or { Speech = 2, Cunning = 1, Strength = 0 }

	self.index = 1
	self.choiceIndex = 1
	self.node = self.script[self.index]
end

function Dialog:enter() end
function Dialog:leave() end

-- helpers
local function injectSequence(list, i, seq)
	for k = #seq, 1, -1 do
		table.insert(list, i + 1, seq[k])
	end
end

local function rollD20()
	return math.random(1, 20)
end

function Dialog:jumpTo(targetIndex)
	self.index = targetIndex
	self.choiceIndex = 1
	self.node = self.script[self.index]
end

function Dialog:advance()
	self.index += 1
	self.choiceIndex = 1
	self.node = self.script[self.index]
end

-- render
function Dialog:update()
	-- header
	gfx.clear(gfx.kColorWhite)
	gfx.fillRoundRect(8, 8, 384 - 16, 24, 8)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	gfx.drawTextInRect("Dialog", 14, 12, 384 - 28, 20)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)

	if not self.node then
		gfx.drawTextAligned("(End of dialog) - B to menu", 192, 120, kTextAlignment.center)
		return
	end

	if self.node.type == "line" then
		if self.node.speaker then gfx.drawText(self.node.speaker .. ":", 16, 56) end
		gfx.drawTextInRect(self.node.text or "", 16, 76, 384 - 32, 96)
		gfx.drawTextAligned("* A next * B menu", 192, 220, kTextAlignment.center)

	elseif self.node.type == "choice" then
		gfx.drawTextInRect(self.node.prompt or "Choose:", 16, 56, 384 - 32, 40)
		for i, opt in ipairs(self.node.options) do
			local y = 110 + (i - 1) * 20
			if i == self.choiceIndex then
				gfx.fillRoundRect(16, y - 2, 352, 18, 6)
				gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
				gfx.drawText(opt.label, 22, y)
				gfx.setImageDrawMode(gfx.kDrawModeCopy)
			else
				gfx.drawText(opt.label, 22, y)
			end
		end
		gfx.drawTextAligned("* A confirm * B menu", 192, 220, kTextAlignment.center)

	elseif self.node.type == "check" then
		local info = string.format("Check: %s vs %d (d20 + stat)", self.node.skill or "?", self.node.difficulty or 10)
		gfx.drawText(info, 16, 56)
		gfx.drawText("Press A to roll. B to menu.", 16, 76)

	else
		gfx.drawTextAligned("(Unknown node type)", 192, 120, kTextAlignment.center)
	end
end

-- input
function Dialog:up()
	if self.node and self.node.type == "choice" then
		self.choiceIndex = ((self.choiceIndex - 2) % #self.node.options) + 1
	end
end

function Dialog:down()
	if self.node and self.node.type == "choice" then
		self.choiceIndex = (self.choiceIndex % #self.node.options) + 1
	end
end

function Dialog:a()
	if not self.node then return end

	if self.node.type == "line" then
		self:advance()

	elseif self.node.type == "choice" then
		local opt = self.node.options[self.choiceIndex]
		if opt.target then self:jumpTo(opt.target) else self:advance() end

	elseif self.node.type == "check" then
		local skill = self.node.skill or "Speech"
		local difficulty  = self.node.difficulty  or 10
		local base  = self.stats[skill] or 0
		local r     = rollD20()
		local total = r + base
		local ok    = (total >= difficulty)

		local log = {
			{ type = "line", speaker = "Narrator",
			  text = string.format("Roll: %d + %s(%d) = %d vs %d -> %s",
					r, skill, base, total, difficulty, ok and "success" or "fail") }
		}

		if ok and self.node.success then
			for _, n in ipairs(self.node.success) do table.insert(log, n) end
		elseif (not ok) and self.node.fail then
			for _, n in ipairs(self.node.fail) do table.insert(log, n) end
		end

		injectSequence(self.script, self.index, log)
		self:advance()
	end
end

function Dialog:b()
	self.switch("menu")
end
