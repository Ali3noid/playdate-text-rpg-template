import "CoreLibs/graphics"
local gfx = playdate.graphics

ChoicePanel = ChoicePanel or {}

function ChoicePanel.draw(state, x, y, w, h)
	local node = state.node
	if not node then return end

	gfx.drawTextInRect(node.prompt or "Choose:", x + 8, y + 8, w - 16, 40)

	local total = (node.options and #node.options) or 0
	local availableHeight = h - 56
	local maxVisible = math.max(1, math.floor(availableHeight / 20))

	local lastVisible = state.choiceFirstVisible + maxVisible - 1
	if state.choiceIndex < state.choiceFirstVisible then
		state.choiceFirstVisible = state.choiceIndex
	elseif state.choiceIndex > lastVisible then
		state.choiceFirstVisible = state.choiceIndex - maxVisible + 1
	end
	if total >= maxVisible then
		local maxStart = total - maxVisible + 1
		if state.choiceFirstVisible > maxStart then state.choiceFirstVisible = maxStart end
	else
		state.choiceFirstVisible = 1
	end
	if state.choiceFirstVisible < 1 then state.choiceFirstVisible = 1 end

	local drawFrom = state.choiceFirstVisible
	local drawTo = math.min(total, drawFrom + maxVisible - 1)
	local lineY = y + 48
	for i = drawFrom, drawTo do
		local option = node.options[i]
		local isAvailable = state:optionIsAvailable(option)
		local labelText = isAvailable and (option.label or "") or (option.lockedLabel or "???")
		if i == state.choiceIndex then
			gfx.fillRoundRect(x + 4, lineY - 2, w - 8, 18, 6)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			gfx.drawText(labelText, x + 10, lineY)
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		else
			gfx.drawText(labelText, x + 10, lineY)
		end
		lineY = lineY + 20
	end

	if state.choiceFirstVisible > 1 then
		gfx.fillTriangle(x + w - 16, y + 44, x + w - 8, y + 44, x + w - 12, y + 38)
	end
	if drawTo < total then
		gfx.fillTriangle(x + w - 16, y + h - 10, x + w - 8, y + h - 10, x + w - 12, y + h - 4)
	end

	gfx.drawTextAligned("* A confirm * B inventory", 192, 220, kTextAlignment.center)
end
