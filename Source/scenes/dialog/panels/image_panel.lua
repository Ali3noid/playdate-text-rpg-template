import "CoreLibs/graphics"
local gfx = playdate.graphics

ImagePanel = ImagePanel or {}

-- simple in-memory cache to avoid reloading images every frame
local _cache = {}

local function getImage(path)
	if not path then return nil end
	local img = _cache[path]
	if img then return img end
	img = gfx.image.new(path)
	_cache[path] = img
	return img
end

-- Fullscreen image (no dialog panel, no tabs). Draws at 0,0.
-- Node fields used: path (required)
function ImagePanel.draw(state)
	gfx.clear(gfx.kColorWhite)

	local node = state.node
	local img = node and getImage(node.path) or nil
	if img then
		-- draw at top-left; recommended size is 400x240
		img:draw(0, 0)
	else
		-- fallback if image not found
		gfx.drawTextAligned("(Image not found: "..tostring(node and node.path or "nil")..")", 200, 110, kTextAlignment.center)
	end
end
