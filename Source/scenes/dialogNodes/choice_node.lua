import "CoreLibs/graphics"
local gfx = playdate.graphics

DialogNodes = DialogNodes or {}
local H = {}

function H.prepare(self)
    self.choiceIndex = 1
    self.choiceFirstVisible = 1
end

function H.draw(self, x, y, w, h)
    gfx.drawTextInRect(self.node.prompt or "Choose:", x + 8, y + 8, w - 16, 40)

    local totalOptions = (self.node.options and #self.node.options) or 0
    local availableHeight = h - 56
    local maxVisibleOptions = math.max(1, math.floor(availableHeight / 20))

    local lastVisible = self.choiceFirstVisible + maxVisibleOptions - 1
    if self.choiceIndex < self.choiceFirstVisible then
        self.choiceFirstVisible = self.choiceIndex
    elseif self.choiceIndex > lastVisible then
        self.choiceFirstVisible = self.choiceIndex - maxVisibleOptions + 1
    end
    if totalOptions >= maxVisibleOptions then
        local maxStart = totalOptions - maxVisibleOptions + 1
        if self.choiceFirstVisible > maxStart then self.choiceFirstVisible = maxStart end
    else
        self.choiceFirstVisible = 1
    end
    if self.choiceFirstVisible < 1 then self.choiceFirstVisible = 1 end

    local drawFrom = self.choiceFirstVisible
    local drawTo = math.min(totalOptions, drawFrom + maxVisibleOptions - 1)
    local lineY = y + 48
    for i = drawFrom, drawTo do
        local option = self.node.options[i]
        local isAvailable = self:optionIsAvailable(option)
        local labelText = isAvailable and (option.label or "") or (option.lockedLabel or "???")
        if i == self.choiceIndex then
            gfx.fillRoundRect(x + 4, lineY - 2, w - 8, 18, 6)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.drawText(labelText, x + 10, lineY)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        else
            gfx.drawText(labelText, x + 10, lineY)
        end
        lineY = lineY + 20
    end

    if self.choiceFirstVisible > 1 then
        gfx.fillTriangle(x + w - 16, y + 44, x + w - 8, y + 44, x + w - 12, y + 38)
    end
    if drawTo < totalOptions then
        gfx.fillTriangle(x + w - 16, y + h - 10, x + w - 8, y + h - 10, x + w - 12, y + h - 4)
    end

    gfx.drawTextAligned("* A confirm * B switch", 192, 220, kTextAlignment.center)
end

function H.up(self)
    local n = #self.node.options
    self.choiceIndex = ((self.choiceIndex - 2) % n) + 1
end

function H.down(self)
    local n = #self.node.options
    self.choiceIndex = (self.choiceIndex % n) + 1
end

function H.a(self)
    local opt = self.node.options[self.choiceIndex]
    if opt then
        local ok = self:optionIsAvailable(opt)
        local trg = (opt and opt.target) or nil
        local lbl = opt.label or "-"
        print(string.format("[Dialog] choose idx=%d label=\"%s\" target=%s [%s]",
            self.choiceIndex, lbl, tostring(trg), ok and "OK" or "LOCK"))
        if ok then
            if trg ~= nil then self:jumpTo(trg) else self:advance() end
        end
    end
end

DialogNodes["choice"] = H
