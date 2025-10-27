import "CoreLibs/graphics"

local gfx = playdate.graphics

--
-- LockPanel
-- This module provides a panel for displaying and interacting with
-- combination locks in the dialog system. The prompt is rendered
-- above the panel and may wrap onto two lines when needed. The
-- dials are drawn within the panel, and control instructions are
-- shown at the bottom of the screen.
--
-- Usage:
--   LockPanel.draw(state, x, y, width, height)
--
-- Parameters:
--   state  - The current dialog state containing node and lock data.
--   x, y   - The top-left coordinates of the panel (dialog box).
--   width  - The width of the panel.
--   height - The height of the panel (unused directly here).

LockPanel = LockPanel or {}

function LockPanel.draw(state, x, y, width, height)
    local node = state.node
    if node == nil then
        return
    end

    -- Draw the prompt above the panel. Allocate space for two lines and
    -- decide whether to wrap or scroll based on the length of the text.
    if node.prompt and #node.prompt > 0 then
        local font = gfx.getFont()
        local fontHeight = (font and font:getHeight()) or 14
        -- Height for two lines plus padding. Use this for the prompt area.
        local promptHeight = fontHeight * 2 + 4
        -- Place the prompt rectangle above the panel with a small gap.
        local promptY = y - promptHeight - 4
        if promptY < 0 then
            promptY = 0
        end
        -- Calculate the maximum text width that can fit in two lines. If the
        -- actual text width exceeds this, enable horizontal scrolling so
        -- players can read the entire message.
        local maxLineWidth = (width - 16) * 2
        local textWidth, _ = gfx.getTextSize(node.prompt)
        if textWidth > maxLineWidth then
            -- Text too long: scroll horizontally across the visible area.
            local visibleWidth = width - 16
            local totalScroll = textWidth + visibleWidth
            -- Speed of scrolling in pixels per second. Adjust as needed.
           local speed = 30
            -- Use the millisecond timer for scrolling; getCurrentTime() is nil on Playdate.
            local currentMs = playdate.getCurrentTimeMilliseconds()
            local scrollOffset = math.floor(((currentMs / 1000) * speed) % totalScroll)
            -- Clip the drawing area to the prompt region.
            gfx.setClipRect(x + 8, promptY, visibleWidth, promptHeight)
            -- Calculate the horizontal position of the text. Starting from the
            -- right edge of the visible area and moving left as time passes.
            local offsetX = x + 8 + visibleWidth - scrollOffset
            gfx.drawText(node.prompt, offsetX, promptY + 2)
            gfx.clearClipRect()
        else
            -- Text fits within two lines: draw normally using wrapping.
            gfx.drawTextInRect(node.prompt, x + 8, promptY, width - 16, promptHeight)
        end
    end

    -- Determine the list of symbols for each dial. Default to digits 0–9.
    local symbols = node.symbols
    if symbols == nil or #symbols == 0 then
        symbols = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }
    end

    -- Determine the number of slots (dials). If not specified, use the length
    -- of the solution if provided, otherwise default to 3.
    local slotCount = node.slots or ((node.solution and #node.solution) or 3)

    -- Retrieve the current values for each dial and the selected dial index.
    local values = state.lockValues or {}
    local selectedIndex = state.lockSlotIndex or 1

    -- Calculate dimensions for each dial. Leave margins around the panel.
    local dialWidth = math.floor((width - 16 - (slotCount - 1) * 8) / math.max(1, slotCount))
    local dialHeight = 56
    -- Y coordinate for drawing dials. Center the row vertically within the
    -- panel's height. Ensure there is at least an 8-pixel margin at the top.
    local dialY = y + math.floor((height - dialHeight) / 2)
    if dialY < y + 8 then
        dialY = y + 8
    end
    local currentX = x + 8

    -- Draw each dial with a border, label, and arrow indicators.
    for index = 1, slotCount do
        local isSelected = (index == selectedIndex)
        if isSelected then
            -- Highlight the selected dial with an outer border.
            gfx.drawRect(currentX - 2, dialY - 2, dialWidth + 4, dialHeight + 4)
        else
            gfx.drawRect(currentX, dialY, dialWidth, dialHeight)
        end

        -- Determine the label for this dial.
        local valueIndex = values[index] or 1
        local label = symbols[valueIndex] or "?"
        local textWidth, textHeight = gfx.getTextSize(label)
        local centerX = currentX + math.floor((dialWidth - textWidth) / 2)
        local centerY = dialY + math.floor((dialHeight - textHeight) / 2)
        gfx.drawText(label, centerX, centerY)

        -- Draw an up arrow above the dial.
        gfx.fillTriangle(
            currentX + dialWidth / 2 - 4, dialY - 8,
            currentX + dialWidth / 2 + 4, dialY - 8,
            currentX + dialWidth / 2,     dialY - 12
        )
        -- Draw a down arrow below the dial.
        gfx.fillTriangle(
            currentX + dialWidth / 2 - 4, dialY + dialHeight + 8,
            currentX + dialWidth / 2 + 4, dialY + dialHeight + 8,
            currentX + dialWidth / 2,     dialY + dialHeight + 12
        )

        currentX = currentX + dialWidth + 8
    end

    -- Draw control instructions along the bottom of the screen. Use the
    -- display height to position text relative to the bottom edge. The
    -- instructions reflect the controls for rotating dials, selecting a
    -- dial, confirming the combination, and opening the inventory.
    local screenHeight = playdate.display.getHeight()
    gfx.drawTextAligned(
        "D-pad select * A confirm  * B inventory",
        192,
        screenHeight - 20,
        kTextAlignment.center
    )
end