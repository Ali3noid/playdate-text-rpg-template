import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/ui"

local gfx <const> = playdate.graphics

class('Menu').extends()

function Menu:init()
	self.items = { "New Game", "Options", "Quit" }
	self.index = 1
end

function Menu:enter()
	self.index = 1
end

function Menu:update()
	-- Frame/header
	gfx.clear(gfx.kColorWhite)
	gfx.fillRoundRect(8, 8, 384 - 16, 24, 8)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	gfx.drawTextInRect("Playdate * Prototype", 14, 12, 384 - 28, 20)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)

	-- Title
	gfx.drawTextAligned("Minimal Menu", 192, 60, kTextAlignment.center)

	-- Items
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

	-- Footer hint
	gfx.drawTextAligned(" * A confirm * B back", 192, 220, kTextAlignment.center)
end

function Menu:up()
	self.index = ((self.index - 2) % #self.items) + 1
end

function Menu:down()
	self.index = (self.index % #self.items) + 1
end

function Menu:a()
	local choice = self.items[self.index]
	-- Use console logging instead of alerts; Playdate SDK does not expose playdate.system.alert
	if choice == "New Game" then
		print("[Menu] New Game selected (stub)")
		-- TODO: switch to Dialog scene when implemented
	elseif choice == "Options" then
		print("[Menu] Options selected (stub)")
	elseif choice == "Quit" then
		print("[Menu] Quit selected (stub)")
		-- NOTE: there's no app-level quit; staying in menu for now
	end
end

function Menu:b()
	-- No-op for now; stays in menu
end
