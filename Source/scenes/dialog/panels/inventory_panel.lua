import "CoreLibs/graphics"
local gfx = playdate.graphics

InventoryPanel = InventoryPanel or {}

function InventoryPanel.draw(state, x, y, w, h)
	-- Panel frame
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRoundRect(x, y, w, h, 8)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(x, y, w, h, 8)

	-- Left column: list
	local listX = x + 8
	local listY = y + 8
	local listW = math.floor((w - 24) * 0.45)
	local listH = h - 16
	local lineH = 14
	gfx.drawRoundRect(listX, listY, listW, listH, 6)

	local ids = state:inventoryIds()
	local count = #ids

	-- Clamp selection
	if count == 0 then
		state.inventorySelectedIndex = 1
	else
		if state.inventorySelectedIndex < 1 then state.inventorySelectedIndex = 1 end
		if state.inventorySelectedIndex > count then state.inventorySelectedIndex = count end
	end

	local maxVisible = math.max(1, math.floor(listH / lineH))
	local firstVisible = math.max(1, state.inventorySelectedIndex - math.floor(maxVisible / 2))
	if firstVisible + maxVisible - 1 > count then
		firstVisible = math.max(1, count - maxVisible + 1)
	end
	local lastVisible = math.min(count, firstVisible + maxVisible - 1)

	local yCursor = listY + 2
	if count == 0 then
		gfx.drawText("(Inventory is empty)", listX + 6, yCursor)
	else
		for i = firstVisible, lastVisible do
			local itemId = ids[i]
			local info = state:itemInfoById(itemId)
			local name = (info and info.name) or tostring(itemId)
			if i == state.inventorySelectedIndex then
				gfx.fillRoundRect(listX + 3, yCursor - 1, listW - 6, lineH, 4)
				gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
				gfx.drawText(name, listX + 8, yCursor)
				gfx.setImageDrawMode(gfx.kDrawModeCopy)
			else
				gfx.drawText(name, listX + 8, yCursor)
			end
			yCursor = yCursor + lineH
			if yCursor > listY + listH - lineH then break end
		end
		-- Scroll arrows
		if firstVisible > 1 then
			gfx.fillTriangle(listX + listW - 14, listY + 6, listX + listW - 6, listY + 6, listX + listW - 10, listY + 1)
		end
		if lastVisible < count then
			local ay = listY + listH - 6
			gfx.fillTriangle(listX + listW - 14, ay, listX + listW - 6, ay, listX + listW - 10, ay + 5)
		end
	end

	-- Right column: description
	local descX = listX + listW + 8
	local descW = w - (descX - x) - 8
	gfx.drawRoundRect(descX, listY, descW, listH, 6)

	local descText = ""
	if count > 0 then
		local selId   = ids[state.inventorySelectedIndex]
		local selInfo = state:itemInfoById(selId)
		local selName = (selInfo and selInfo.name) or tostring(selId)
		local selDesc = (selInfo and selInfo.description) or ""
		gfx.drawText("* " .. selName, descX + 8, listY + 6)
		gfx.drawTextInRect(selDesc, descX + 8, listY + 24, descW - 16, listH - 32)
	else
		gfx.drawTextInRect("(Select items to see their descriptions here.)",
			descX + 8, listY + 8, descW - 16, listH - 16)
	end

	gfx.drawTextAligned("* Up/Down select  * B back", 192, 220, kTextAlignment.center)
end
