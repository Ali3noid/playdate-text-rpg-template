import "CoreLibs/graphics"

DialogNodes = DialogNodes or {}

local gfx = playdate.graphics
local pd = playdate

local H = {}
H.fullscreen = true  -- gives signal to dialog.lua to not draw panel

-- Fields supported:
--   image (string, required)   -- image path, e.g. "assets/intro"
--   caption (string, optional) -- small text at the bottom
--   waitForA (bool, default=true)
--   durationSeconds (number, optional; auto‑advance if waitForA=false)

function H.prepare(self)
		self._imageCache = self._imageCache or {}
		local path = assert(self.node.image, "image_node: missing 'image' path")

		if not self._imageCache[path] then
				local img = gfx.image.new(path)
				assert(img, "image_node: failed to load image: " .. tostring(path))
				self._imageCache[path] = img
		end

		self._img = self._imageCache[path]
		self._imgAutoAdvanceAt = nil
		self._imgHasAdvanced = false

		local waitForA = (self.node.waitForA ~= false)
		local duration = tonumber(self.node.durationSeconds)

		if (not waitForA) and duration and duration > 0 then
				self._imgAutoAdvanceAt = pd.getCurrentTimeMilliseconds() + math.floor(duration * 1000)
		end
end

local function drawCenteredImage(img)
		local iw, ih = img:getSize()
		local x = math.floor((400 - iw) / 2)
		local y = math.floor((240 - ih) / 2)
		img:draw(x, y)
end

local function maybeAutoAdvance(self)
		if self._imgHasAdvanced then return end
		if not self._imgAutoAdvanceAt then return end
		if playdate.getCurrentTimeMilliseconds() >= self._imgAutoAdvanceAt then
				self._imgHasAdvanced = true
				if self.node.target ~= nil then self:jumpTo(self.node.target) else self:advance() end
		end
end

function H.draw(self, _x, _y, _w, _h)
		-- full screen background already cleared by Dialog
		if self._img then drawCenteredImage(self._img) end

		if self.node.caption and #self.node.caption > 0 then
				gfx.drawTextAligned(self.node.caption, 200, 210, kTextAlignment.center)
		end

		local waitForA = (self.node.waitForA ~= false)
		if waitForA then
				gfx.drawTextAligned("* A continue * B switch", 200, 226, kTextAlignment.center)
		end

		maybeAutoAdvance(self)
end

function H.a(self)
		if self._imgHasAdvanced then return end
		local waitForA = (self.node.waitForA ~= false)
		if waitForA or not self._imgAutoAdvanceAt then
				self._imgHasAdvanced = true
				if self.node.target ~= nil then self:jumpTo(self.node.target) else self:advance() end
		end
end

DialogNodes["image"] = H
