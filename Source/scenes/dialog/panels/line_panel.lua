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

	-- Measure wrapped text height to know if it overflows the panel
	local innerX, innerY = x + 8, y + 8
	local innerW, innerH = w - 16, h - 16
	local _, wrappedHeight = gfx.getTextSizeForMaxWidth(textToDraw, innerW)
	wrappedHeight = math.max(wrappedHeight, 0)

	-- Update max scroll in state so controller can react to Up/Down/A
	state.lineMaxScroll = math.max(0, wrappedHeight - innerH)
	state.lineScrollY = math.max(0, math.min(state.lineScrollY or 0, state.lineMaxScroll))

	-- Clip drawing to the panel and render full text shifted by scroll
	gfx.setClipRect(innerX, innerY, innerW, innerH)
	gfx.drawTextInRect(textToDraw, innerX, innerY - state.lineScrollY, innerW, wrappedHeight)
	gfx.clearClipRect()

	-- Optional scrollbar if overflow exists
	if state.lineMaxScroll > 0 then
		local trackX = x + w - 6
		local trackY = innerY
		local trackH = innerH
		-- Track
		gfx.drawLine(trackX, trackY, trackX, trackY + trackH)
		-- Thumb size and position
		local ratio = innerH / (wrappedHeight)
		local thumbH = math.max(8, math.floor(trackH * ratio))
		local maxThumbOffset = trackH - thumbH
		local thumbOffset = 0
		if state.lineMaxScroll > 0 then
			thumbOffset = math.floor((state.lineScrollY / state.lineMaxScroll) * maxThumbOffset)
		end
		gfx.fillRoundRect(trackX - 2, trackY + thumbOffset, 4, thumbH, 2)
	end

	-- Footer hint depends on typing state and overflow
	local footer
	if state.typing then
		footer = "* A skip * B inventory"
	else
		if state.lineMaxScroll > 0 and (state.lineScrollY or 0) < state.lineMaxScroll then
			footer = "Up/Down scroll * A bottom * B inventory"
		else
			footer = "* A next * B inventory"
		end
	end
	gfx.drawTextAligned(footer, 192, 220, kTextAlignment.center)
end
