import "CoreLibs/graphics"
local gfx = playdate.graphics

CheckPanel = CheckPanel or {}

local function drawDiceRow(label, values, x, y, maxWidth, markSuccess)
	gfx.drawText(label, x + 8, y)
	local startX = x + 60
	local box = 16
	local gap = 2
	local cursor = startX
	for i, v in ipairs(values or {}) do
		if cursor + box > x + maxWidth - 8 then break end
		if markSuccess and v >= 5 then
			gfx.fillRect(cursor, y - 2, box, box)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			gfx.drawText(tostring(v), cursor + 4, y)
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		else
			gfx.drawRect(cursor, y - 2, box, box)
			gfx.drawText(tostring(v), cursor + 4, y)
		end
		cursor = cursor + box + gap
	end
	return y + 22
end

function CheckPanel.draw(state, x, y, w, h)
	local node = state.node
	if not node then return end

	local skillName       = node.skill or "?"
	local difficultyValue = node.difficulty or 1
	local baseStat        = state.stats[skillName] or 0
	local misfortune      = (state.checks and state.checks:getMisfortune()) or 0

	if state.mode == "diceSelect" then
		gfx.drawText(string.format("Select Risk Dice (0-2): %d", state.riskDiceCount), x + 8, y + 8)
		gfx.drawText(string.format("Misfortune: %d", misfortune), x + 8, y + 28)
		gfx.drawText("Use up/down to choose, A to roll, B to inventory.", x + 8, y + 48)
		gfx.drawTextAligned("* A roll * B inventory", 192, 220, kTextAlignment.center)

	elseif state.mode == "diceResult" then
		local r = state.testResult
		local yy = y + 8
		yy = drawDiceRow("Raw:",     r and r.rawRoll     or {}, x, yy, w, false)
		yy = drawDiceRow("Adjusted:",r and r.finalRoll   or {}, x, yy, w, true)
		if r then
			local resultTxt = string.format("Successes: %d/%d -> %s", r.successes, difficultyValue, r.passed and "success" or "fail")
			gfx.drawText(resultTxt, x + 8, yy); yy = yy + 18
			local misText
			if state.riskDiceCount > 0 and not r.passed then
				misText = string.format("Misfortune: %d -> %d", r.misfortuneBefore, r.misfortuneAfter)
			else
				misText = string.format("Misfortune: %d", r.misfortuneBefore)
			end
			gfx.drawText(misText, x + 8, yy)
		end
		gfx.drawTextAligned("* A continue * B inventory", 192, 220, kTextAlignment.center)

	else
		local infoText = string.format("Test: %s vs %d (d6 + stat)", skillName, difficultyValue)
		local diceInfo = string.format("Dice: %d (stat) + Risk ? | Misfortune: %d", baseStat, misfortune)
		gfx.drawText(infoText, x + 8, y + 8)
		gfx.drawText(diceInfo, x + 8, y + 28)
		gfx.drawText("Press A to select Risk Dice, B to inventory.", x + 8, y + 48)
		gfx.drawTextAligned("* A select * B inventory", 192, 220, kTextAlignment.center)
	end
end
