import "CoreLibs/graphics"
local gfx = playdate.graphics

LinePanel = LinePanel or {}

function LinePanel.draw(state, x, y, w, h)
	local node = state.node
	if not node then return end

	local textToDraw = state.currentText:sub(1, state.textPos)
	if node.speaker then
		local font = gfx.getFont()
		local fontHeight = (font and font:getHeight()) or 14
		local speakerY = math.max(0, y - fontHeight - 4)
		gfx.drawText(node.speaker .. ":", x + 8, speakerY)
	end
	gfx.drawTextInRect(textToDraw, x + 8, y + 8, w - 16, h - 16)
	gfx.drawTextAligned(state.typing and "* A skip * B inventory" or "* A next * B inventory", 192, 220, kTextAlignment.center)
end
