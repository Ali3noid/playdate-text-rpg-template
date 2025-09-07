-- path: Source/scenes/dialog_nodes/chapterEnd_node.lua
import "CoreLibs/graphics"

DialogNodes = DialogNodes or {}

local gfx <const> = playdate.graphics
local pd  <const> = playdate

local H = {}
H.fullscreen = true 

-- Fields supported:
--   title (string, optional)        -- big title line
--   subtitle (string, optional)     -- small subtitle
--   waitForA (bool, default=true)   -- press A to continue
--   durationSeconds (number, optional; auto-advance if waitForA=false)
--   nextModule (string, optional)   -- e.g. "data/chapter_02" (will import)
--   nextGlobal (string, required)   -- e.g. "DIALOG_02" (global table name in nextModule)
--
-- On continue:
--   - If nextGlobal exists (after optional import), switches to new Dialog with:
--       script = _G[nextGlobal], stats = self.stats, inventory = self.inventory
--   - If nextGlobal is missing -> error (assert)

local function doTransition(self)
	local nextGlobal = assert(self.node.nextGlobal, "chapterEnd_node: missing 'nextGlobal'")

	if self.node.nextModule and type(self.node.nextModule) == "string" and #self.node.nextModule > 0 then
		import(self.node.nextModule)
	end

	local scriptTable = _G[nextGlobal]
	assert(scriptTable, "chapterEnd_node: nextGlobal not found: " .. tostring(nextGlobal))

	-- carry over stats & inventory
	self.switch("dialog", {
		script    = scriptTable,
		stats     = self.stats,
		inventory = self.inventory
	})
end

function H.prepare(self)
	self._endAutoAt = nil
	self._hasContinued = false

	local waitForA = (self.node.waitForA ~= false)
	local duration = tonumber(self.node.durationSeconds)
	if (not waitForA) and duration and duration > 0 then
		self._endAutoAt = pd.getCurrentTimeMilliseconds() + math.floor(duration * 1000)
	end
end

local function maybeAuto(self)
	if self._hasContinued then return end
	if not self._endAutoAt then return end
	if playdate.getCurrentTimeMilliseconds() >= self._endAutoAt then
		self._hasContinued = true
		doTransition(self)
	end
end

function H.draw(self, _x, _y, _w, _h)
	local title   = self.node.title or "Chapter Complete"
	local subtitle = self.node.subtitle or ""

	gfx.drawTextAligned(title,   200, 100, kTextAlignment.center)
	if #subtitle > 0 then
		gfx.drawTextAligned(subtitle, 200, 120, kTextAlignment.center)
	end

	local waitForA = (self.node.waitForA ~= false)
	if waitForA then
		gfx.drawTextAligned("* A continue * B menu", 200, 200, kTextAlignment.center)
	end

	maybeAuto(self)
end

function H.a(self)
	if self._hasContinued then return end
	self._hasContinued = true
	doTransition(self)
end

DialogNodes["chapterEnd"] = H
