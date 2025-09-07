-- path: Source/scenes/dialog_nodes/check_node.lua
import "CoreLibs/graphics"
local gfx = playdate.graphics

DialogNodes = DialogNodes or {}
local H = {}

function H.prepare(self)
    -- nothing special; UI opens on A
end

local function drawDiceRow(label, values, markSuccess, x, y, boxX, boxW)
    gfx.drawText(label, x + 8, y)
    local drawX = x + 60
    for i, v in ipairs(values or {}) do
        local dx = drawX + (i - 1) * 18
        if dx + 16 > boxX + boxW - 8 then break end
        if markSuccess and v >= 5 then
            gfx.fillRect(dx, y - 2, 16, 16)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.drawText(tostring(v), dx + 4, y)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        else
            gfx.drawRect(dx, y - 2, 16, 16)
            gfx.drawText(tostring(v), dx + 4, y)
        end
    end
    return y + 22
end

function H.draw(self, x, y, w, h)
    local skillName       = self.node.skill or "?"
    local difficultyValue = self.node.difficulty or 1
    local baseStat        = self.stats[skillName] or 0
    local misfortune      = (self.checks and self.checks:getMisfortune()) or 0

    if self.mode == "diceSelect" then
        gfx.drawText(string.format("Select Risk Dice (0-2): %d", self.riskDiceCount), x + 8, y + 8)
        gfx.drawText(string.format("Misfortune: %d", misfortune), x + 8, y + 28)
        gfx.drawText("Use up/down to choose, A to roll, B to menu.", x + 8, y + 48)
        gfx.drawTextAligned("* A roll * B menu", 192, 220, kTextAlignment.center)

    elseif self.mode == "diceResult" then
        local r = self.testResult
        if r then
            local yy = y + 8
            yy = drawDiceRow("Raw:", r.rawRoll, false, x, yy, x, w)
            yy = drawDiceRow("Adjusted:", r.finalRoll, true, x, yy, x, w)
            local resultTxt = string.format("Successes: %d/%d -> %s", r.successes, difficultyValue, r.passed and "success" or "fail")
            gfx.drawText(resultTxt, x + 8, yy); yy = yy + 18
            local misText
            if self.riskDiceCount > 0 and not r.passed then
                misText = string.format("Misfortune: %d -> %d", r.misfortuneBefore, r.misfortuneAfter)
            else
                misText = string.format("Misfortune: %d", r.misfortuneBefore)
            end
            gfx.drawText(misText, x + 8, yy)
        end
        gfx.drawTextAligned("* A continue * B menu", 192, 220, kTextAlignment.center)

    else
        local infoText = string.format("Test: %s vs %d (d6 + stat)", skillName, difficultyValue)
        local diceInfo = string.format("Dice: %d (stat) + Risk ? | Misfortune: %d", baseStat, misfortune)
        gfx.drawText(infoText, x + 8, y + 8)
        gfx.drawText(diceInfo, x + 8, y + 28)
        gfx.drawText("Press A to select Risk Dice, B to menu.", x + 8, y + 48)
        gfx.drawTextAligned("* A select * B menu", 192, 220, kTextAlignment.center)
    end
end

function H.up(self)
    if self.mode == "diceSelect" then
        self.riskDiceCount = math.max(0, self.riskDiceCount - 1)
    end
end

function H.down(self)
    if self.mode == "diceSelect" then
        self.riskDiceCount = math.min(2, self.riskDiceCount + 1)
    end
end

function H.a(self)
    -- Stage 1: open selector
    if self.mode == nil then
        self.mode = "diceSelect"
        self.riskDiceCount = 0
        self.testResult = nil
        return
    end
    -- Stage 2: roll
    if self.mode == "diceSelect" then
        local skillName       = self.node.skill or "?"
        local difficultyValue = self.node.difficulty or 1
        local baseStat        = self.stats[skillName] or 0
        self.testResult = self.checks:performTest(baseStat, 0, difficultyValue, self.riskDiceCount)
        self.mode = "diceResult"
        return
    end
    -- Stage 3: inject summary + branch
    if self.mode == "diceResult" then
        local r = self.testResult
        if not r then
            self.mode = nil
            self.riskDiceCount = 0
            self:advance()
            return
        end
        local isSuccess       = r.passed
        local difficultyValue = self.node.difficulty or 1

        local rollInfoLine = {
            type = "midCheckLine",
            speaker = "Narrator",
            text = string.format(
                "Rolls: %s -> %s | Successes: %d/%d -> %s",
                table.concat(r.rawRoll, ", "),
                table.concat(r.finalRoll, ", "),
                r.successes, difficultyValue,
                isSuccess and "success" or "fail"
            )
        }

        local branchSeq = isSuccess and self.node.success or self.node.fail
        local defaultTarget = isSuccess and self.node.successTarget or self.node.failTarget

        local splice = {}
        table.insert(splice, rollInfoLine)
        if branchSeq then
            for _, el in ipairs(branchSeq) do table.insert(splice, el) end
        end
        if (not self:sequenceHasExplicitRouting(branchSeq)) and defaultTarget then
            local lastIdx = self:findLastRoutableIndex(branchSeq)
            if lastIdx then
                branchSeq[lastIdx].target = defaultTarget
            else
                rollInfoLine.type = "line"
                rollInfoLine.target = defaultTarget
            end
        end
        for off, el in ipairs(splice) do
            table.insert(self.script, self.posIndex + off, el)
        end

        self:rebuildIdMap()

        self.mode = nil
        self.riskDiceCount = 0
        self.testResult = nil
        self:advance()
    end
end

DialogNodes["check"] = H
