import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/ui"
import "data/dialog_01"  -- added

local gfx <const> = playdate.graphics

class('Menu').extends()

function Menu:init(config)
	self.switch = assert(config and config.switch, "Menu: missing switch()")
	self.items = { "New Game", "Options", "Quit" }
	self.index = 1
end

function Menu:enter()
	self.index = 1
end

function Menu:update()
	gfx.clear(gfx.kColorWhite)
	gfx.fillRoundRect(8, 8, 384 - 16, 24, 8)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	gfx.drawTextInRect("Playdate Prototype", 14, 12, 384 - 28, 20)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)

	gfx.drawTextAligned("Minimal Menu", 192, 60, kTextAlignment.center)

	for i, label in ipairs(self.items) do
		local y = 100 + (i - 1) * 22
		if i == self.index then
			gfx.fillRoundRect(92, y - 2, 200, 20, 6)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			gfx.drawTextAligned(label, 192, y, kTextAlignment.center)
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		else
			gfx.drawTextAligned(label, 192, y, kTextAlignment.center)
		end
	end

	gfx.drawTextAligned("^/v select - A confirm - B back", 192, 220, kTextAlignment.center)
end

function Menu:up()   self.index = ((self.index - 2) % #self.items) + 1 end
function Menu:down() self.index = (self.index % #self.items) + 1 end

function Menu:a()
	local choice = self.items[self.index]
	if choice == "New Game" then
		print("[Menu] New Game selected")
		self.switch("dialog", { script = DIALOG_01, stats = { Speech = 2, Cunning = 1, Strength = 0 } })
	elseif choice == "Options" then
		print("[Menu] Options selected")
	elseif choice == "Quit" then
		print("[Menu] Quit selected")
	end
end

function Menu:b() end
