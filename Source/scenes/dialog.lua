import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/ui"

local gfx <const> = playdate.graphics

class('Dialog').extends()

function Dialog:init(config)
	-- Dependencies and data
	self.switch = assert(config and config.switch, "Dialog: missing switch()")
	-- If no script provided, use a tiny built-in sample
	self.script = config.script or {
		{ type = "line",   speaker = "Narrator", text = "You wake up to the sound of the crank." },
		{ type = "choice", prompt  = "What do you do?", options = {
			{ label = "Look around", target = 5 },
			{ label = "Call out",    target = 8 },
		}},
		-- buffer entries (indices 3-4)
		{ type = "line", speaker = "Narrator", text = "(buffer)" },
		{ type = "line", speaker = "Narrator", text = "(buffer)" },
		-- id 5
		{ type = "line", speaker = "You", text = "I look around the room." },
		{ type = "line", speaker = "Narrator", text = "Nothing unusual. A quiet morning." },
		{ type = "line", speaker = "Narrator", text = "Press B to return to menu." },
		-- id 8
		{ type = "line", speaker = "You", text = "Hello? Anyone there?" },
		{ type = "line", speaker = "Narrator", text = "Only silence answers you." },
		{ type = "line", speaker = "Narrator", text = "Press B to return to menu." },
	}

	self.index = 1
	self.choiceIndex = 1
	self.node = self.script[self.index]
end

function Dialog:enter() end
function Dialog:leave() end

-- Navigation helpers
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

-- Render
function Dialog:update()
	-- Header
	gfx.clear(gfx.kColorWhite)
	gfx.fillRoundRect(8, 8, 384 - 16, 24, 8)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	gfx.drawTextInRect("Playdate Dialog", 14, 12, 384 - 28, 20)
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
	else
		gfx.drawTextAligned("(Unknown node type)", 192, 120, kTextAlignment.center)
	end
end

-- Input
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
		if opt.target then
			self:jumpTo(opt.target)
		else
			self:advance()
		end
	end
end

function Dialog:b()
	self.switch("menu")
end
