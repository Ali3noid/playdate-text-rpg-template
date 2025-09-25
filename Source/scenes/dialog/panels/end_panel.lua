import "CoreLibs/graphics"
local gfx = playdate.graphics

EndPanel = EndPanel or {}

-- Draws a simple end-of-chapter card inside a panel.
-- Node fields used: text (optional), target (optional)
function EndPanel.draw(state, x, y, w, h)
	-- panel background
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRoundRect(x, y, w, h, 8)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(x, y, w, h, 8)

	local msg = (state.node and state.node.text) or "The chapter ends here."
	gfx.drawTextAligned("End of Chapter", 200, y + 10, kTextAlignment.center)
	gfx.drawTextInRect(msg, x + 12, y + 36, w - 24, h - 64)

	gfx.drawTextAligned("* A continue", 200, 220, kTextAlignment.center)
end
