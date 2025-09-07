-- path: Source/scenes/dialog_nodes/line_node.lua
import "CoreLibs/graphics"
local gfx = playdate.graphics

DialogNodes = DialogNodes or {}
local H = {}

function H.prepare(self)
    self.currentText  = (self.node and (self.node.text or "")) or ""
    self.textPos      = 0
    self.typing       = true
    self.frameCounter = 0
end

local function drawSpeaker(self, x, y)
    if self.node.speaker then
        local font = gfx.getFont()
        local fontHeight = (font and font:getHeight()) or 14
        local speakerY = math.max(0, y - fontHeight - 4)
        gfx.drawText(self.node.speaker .. ":", x + 8, speakerY)
    end
end

function H.draw(self, x, y, w, h)
    if self.typing then
        self.frameCounter += 1
        if self.frameCounter >= self.charInterval then
            self.frameCounter = 0
            if self.textPos < #self.currentText then
                self.textPos += 1
            else
                self.typing = false
            end
        end
    end
    drawSpeaker(self, x, y)
    local textToDraw = self.currentText:sub(1, self.textPos)
    gfx.drawTextInRect(textToDraw, x + 8, y + 8, w - 16, h - 16)
    gfx.drawTextAligned(self.typing and "* A skip * B menu" or "* A next * B menu", 192, 220, kTextAlignment.center)
end

function H.a(self)
    if self.typing then
        self.textPos = #self.currentText
        self.typing = false
    else
        if self.node.target ~= nil then self:jumpTo(self.node.target) else self:advance() end
    end
end

DialogNodes["line"] = H
