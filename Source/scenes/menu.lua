import "CoreLibs/object"
import "CoreLibs/graphics"
import "data/dialog_01"
import "data/dialog_combine_test"
import "data/dialog_image_test"
import "systems/inventory"
import "data/dialog_chapter01"
import "data/dialog_image_test"
import "data/dialog_item_test"
import "data/dialog_stat_test"

local gfx <const> = playdate.graphics

class('Menu').extends()

function Menu:init(config)
	self.switch = assert(config and config.switch, "Menu: missing switch()")

	self.items = {
		"New Game",
		"Image Test",
		"Item Test",
		"Stat Test",
		"Options",
		"Quit"
	}

	self.selectedIndex = 1

	-- Scrolling window config
	self.visibleCount = 3
	self.firstVisibleIndex = 1

	-- Layout config
	self.titleY = 56
	self.footerY = 220
	self.listX = 62        -- centered for virtual width ~= 384
	self.listY = 88
	self.listWidth = 260
	self.rowHeight = 22
	self.listPadding = 8   -- inner padding inside the frame
	self.cornerRadius = 8
end

function Menu:leave()
	-- No resources to clean yet.
end

local function drawTitleBar()
	gfx.fillRoundRect(8, 8, 384 - 16, 24, 8)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	gfx.drawTextInRect("Playdate * Prototype *", 14, 12, 384 - 28, 20)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function Menu:update()
	gfx.clear(gfx.kColorWhite)
	drawTitleBar()

	-- Title
	gfx.drawTextAligned("Main Menu", 192, self.titleY, kTextAlignment.center)

	-- Compute frame size for 3 rows
	local innerH = (self.rowHeight * self.visibleCount)
	local frameW = self.listWidth
	local frameH = innerH + self.listPadding * 2

	-- Frame
	gfx.drawRoundRect(self.listX, self.listY, frameW, frameH, self.cornerRadius)

	-- Scroll indicators (ASCII)
	local hasAbove = self.firstVisibleIndex > 1
	local lastVisible = math.min(#self.items, self.firstVisibleIndex + self.visibleCount - 1)
	local hasBelow = lastVisible < #self.items
	if hasAbove then
		gfx.drawTextAligned("^", self.listX + frameW - 10, self.listY - 12, kTextAlignment.center)
	end
	if hasBelow then
		gfx.drawTextAligned("v", self.listX + frameW - 10, self.listY + frameH + 2, kTextAlignment.center)
	end

	-- Items
	local startY = self.listY + self.listPadding
	for i = 0, self.visibleCount - 1 do
		local itemIndex = self.firstVisibleIndex + i
		if itemIndex > #self.items then break end
		local label = self.items[itemIndex]
		local rowY = startY + i * self.rowHeight

		if itemIndex == self.selectedIndex then
			-- Highlight selected row
			gfx.fillRoundRect(self.listX + 4, rowY + 2, frameW - 8, self.rowHeight - 4, 6)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			gfx.drawTextAligned(label, self.listX + frameW / 2, rowY + 3, kTextAlignment.center)
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		else
			gfx.drawTextAligned(label, self.listX + frameW / 2, rowY + 3, kTextAlignment.center)
		end
	end

	-- Footer
	gfx.drawTextAligned("* A select  * Up/Down scroll  * B inventory", 192, self.footerY, kTextAlignment.center)
end

-- Keep selected inside the visible window
function Menu:updateWindowAfterMove()
	if self.selectedIndex < self.firstVisibleIndex then
		self.firstVisibleIndex = self.selectedIndex
	end
	local lastVisible = self.firstVisibleIndex + self.visibleCount - 1
	if self.selectedIndex > lastVisible then
		self.firstVisibleIndex = self.selectedIndex - self.visibleCount + 1
	end
	-- Clamp window in bounds
	if self.firstVisibleIndex < 1 then self.firstVisibleIndex = 1 end
	local maxFirst = math.max(1, #self.items - self.visibleCount + 1)
	if self.firstVisibleIndex > maxFirst then self.firstVisibleIndex = maxFirst end
end

function Menu:up()
	self.selectedIndex -= 1
	if self.selectedIndex < 1 then
		self.selectedIndex = #self.items
	end
	self:updateWindowAfterMove()
end

function Menu:down()
	self.selectedIndex += 1
	if self.selectedIndex > #self.items then
		self.selectedIndex = 1
	end
	self:updateWindowAfterMove()
end

function Menu:a()
	local choice = self.items[self.selectedIndex]
	if choice == "New Game" then
		print("[Menu] New Game selected")
		local inv = Inventory()
		self.switch("dialog", {
			script = DIALOG_CHAPTER01,
			stats  = { Runes = 1, Curses = 1, Strength = 1 },
			inventory = inv
		})

	elseif choice == "Image Test" then
		print("[Menu] Image Test selected")
		self.switch("dialog", {
			script = DIALOG_IMAGE_TEST,
			stats  = { Speech = 1, Cunning = 1, Strength = 1 }
		})

	elseif choice == "Item Test" then
		print("[Menu] Item Test selected")
		local inv = Inventory()
		self.switch("dialog", {
			script = DIALOG_ITEM_TEST,
			stats  = { Strength = 1, Luck = 0 },
			inventory = inv
		})

	elseif choice == "Stat Test" then
		print("[Menu] Stat Test selected")
		local inv = Inventory()
		self.switch("dialog", {
			script = DIALOG_STAT_TEST,
			stats  = { Strength = 1, Luck = 0 },
			inventory = inv
		})

	elseif choice == "Options" then
		print("[Menu] Options selected")

	elseif choice == "Quit" then
		print("[Menu] Quit selected")
	end
end

function Menu:b()
	-- No-op here; B is used inside dialog for inventory.
end
