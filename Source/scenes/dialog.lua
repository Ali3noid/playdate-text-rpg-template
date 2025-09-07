-- path: Source/scenes/dialog.lua
import "CoreLibs/object"
import "CoreLibs/graphics"
import "systems/checks"

-- Register all node handlers (each file populates DialogNodes table)
import "scenes/dialogNodes/line_node"
import "scenes/dialogNodes/midCheckLine_node"
import "scenes/dialogNodes/item_node"
import "scenes/dialogNodes/stat_node"
import "scenes/dialogNodes/choice_node"
import "scenes/dialogNodes/check_node"
import "scenes/dialogNodes/image_node"
import "scenes/dialogNodes/chapterEnd_node"

local gfx = playdate.graphics

-- Global registry for node handlers
DialogNodes = DialogNodes or {}

class('Dialog').extends()

-- ===== Helpers for ID map =====
local function buildIdMap(script)
    local map = {}
    for idx, node in ipairs(script) do
        local id = node and node.id
        if id ~= nil then
            assert(type(id) == "number", "Dialog: node.id must be a number")
            assert(map[id] == nil, "Dialog: duplicate node.id=" .. tostring(id))
            map[id] = idx
        end
    end
    return map
end

local function formatTarget(v)
    if v == nil then return "nil" end
    return tostring(v)
end

-- Exposed so handlers can use them via self:sequenceHasExplicitRouting(...)
function Dialog:sequenceHasExplicitRouting(seq)
    if not seq then return false end
    for _, n in ipairs(seq) do
        if n.target ~= nil then return true end
        if n.type == "jump" then return true end
    end
    return false
end

function Dialog:findLastRoutableIndex(seq)
    if not seq then return nil end
    for i = #seq, 1, -1 do
        local n = seq[i]
        if n and n.type ~= "midCheckLine" then
            return i
        end
    end
    return nil
end

-- ===== Class =====
function Dialog:init(arg1, script, stats, inventory)
    local cfg
    if type(arg1) == "table" then
        cfg            = arg1
        self.switch    = assert(cfg.switch, "Dialog: missing switch()")
        self.script    = assert(cfg.script, "Dialog: missing script table")
        self.stats     = cfg.stats or {}
        self.inventory = cfg.inventory or {}
    else
        self.switch    = assert(arg1, "Dialog: missing switch()")
        self.script    = assert(script, "Dialog: missing script table")
        self.stats     = stats or {}
        self.inventory = inventory or {}
    end

    -- Build initial id map
    self.idToPos = buildIdMap(self.script)

    -- State
    self.posIndex     = 1
    self.currentId    = nil
    self.node         = nil
    self.choiceIndex  = 1
    self.choiceFirstVisible = 1

    -- typing effect (used by several handlers)
    self.currentText  = ""
    self.textPos      = 0
    self.typing       = false
    self.charInterval = 2
    self.frameCounter = 0

    -- Checks system state (used by check handler)
    self.mode          = nil      -- nil | "diceSelect" | "diceResult"
    self.riskDiceCount = 0
    self.testResult    = nil
    self.checks        = Checks()

    if self.idToPos[1] then self:enterById(1) else self:enterByPos(1) end
end

-- ===== Enter / Jump =====
function Dialog:rebuildIdMap()
    self.idToPos = buildIdMap(self.script)
end

function Dialog:enterByPos(pos)
    self.posIndex = pos
    self.node     = self.script[self.posIndex]
    self.currentId = (self.node and self.node.id) or nil

    -- reset generic UI states
    self.choiceIndex = 1
    self.choiceFirstVisible = 1
    self.mode          = nil
    self.riskDiceCount = 0
    self.testResult    = nil

    -- prepare handler-specific state
    local h = self.node and DialogNodes[self.node.type] or nil
    if h and h.prepare then h.prepare(self) else self.typing = false end

    self:logNode()
end

function Dialog:enterById(id)
    local pos = self.idToPos[id]
    assert(pos, "Dialog: unknown node id=" .. tostring(id))
    self:enterByPos(pos)
end

function Dialog:jumpTo(targetId)
    assert(targetId ~= nil, "Dialog: jumpTo() missing target id")
    self:enterById(targetId)
end

function Dialog:advance()
    self:enterByPos(self.posIndex + 1)
end

-- ===== Logging =====
function Dialog:logNode()
    if not self.node then
        print(string.format("[Dialog] enter pos=%d id=nil (nil node)", self.posIndex or -1))
        return
    end
    local t = tostring(self.node.type)
    local idStr = (self.node.id ~= nil) and tostring(self.node.id) or "nil"
    if t == "line" or t == "item" or t == "stat" or t == "midCheckLine" then
        local speaker = self.node.speaker or "-"
        local textPrev = (self.node.text and #self.node.text > 40) and (self.node.text:sub(1,37).."...") or (self.node.text or "")
        local targetStr = formatTarget(self.node.target)
        if t == "item" then
            local itemName = self.node.item or "-"
            print(string.format("[Dialog] enter pos=%d id=%s type=item item=%s speaker=%s target=%s text=\"%s\"",
                self.posIndex, idStr, itemName, speaker, targetStr, textPrev))
        elseif t == "stat" then
            local statName = self.node.stat or "-"
            local delta = tostring(self.node.delta or 0)
            print(string.format("[Dialog] enter pos=%d id=%s type=stat stat=%s delta=%s speaker=%s target=%s text=\"%s\"",
                self.posIndex, idStr, statName, delta, speaker, targetStr, textPrev))
        else
            print(string.format("[Dialog] enter pos=%d id=%s type=%s speaker=%s target=%s text=\"%s\"",
                self.posIndex, idStr, t, speaker, targetStr, textPrev))
        end
    elseif t == "choice" then
        local prompt = self.node.prompt or "-"
        local count  = (self.node.options and #self.node.options) or 0
        print(string.format("[Dialog] enter pos=%d id=%s type=choice prompt=\"%s\" options=%d",
            self.posIndex, idStr, prompt, count))
        if self.node.options then
            for i, opt in ipairs(self.node.options) do
                local ok = self:optionIsAvailable(opt)
                local lbl = opt.label or "-"
                local trg = formatTarget(opt.target)
                print(string.format("  [opt %d] %s target=%s [%s]", i, lbl, trg, ok and "OK" or "LOCK"))
            end
        end
    elseif t == "check" then
        local skill = self.node.skill or "?"
        local diff  = self.node.difficulty or 10
        local sT    = formatTarget(self.node.successTarget)
        local fT    = formatTarget(self.node.failTarget)
        print(string.format("[Dialog] enter pos=%d id=%s type=check skill=%s difficulty=%d successTarget=%s failTarget=%s",
            self.posIndex, idStr, skill, diff, sT, fT))
    else
        local trg = formatTarget(self.node.target)
        print(string.format("[Dialog] enter pos=%d id=%s type=%s target=%s", self.posIndex, idStr, t, trg))
    end
end

-- ===== Choice locks =====
function Dialog:optionIsAvailable(opt)
    if opt.requireStat then
        local need = opt.requireStat.value or 0
        local cur  = self.stats[opt.requireStat.name or ""] or 0
        if cur < need then return false end
    end
    if opt.requireItem then
        local have = false
        for _, item in ipairs(self.inventory) do
            if item == opt.requireItem then have = true break end
        end
        if not have then return false end
    end
    return true
end

-- ===== Panel Layout + Update/Draw =====
function Dialog:_panelLayout(nodeType)
    local boxX, boxY, boxW, boxH = 16, 64, 384 - 32, 100
    if nodeType == "line" or nodeType == "item" or nodeType == "stat" or nodeType == "midCheckLine" then
        boxY, boxH = 64, 100
    elseif nodeType == "choice" then
        local count = (self.node.options and #self.node.options) or 0
        local wanted = 48 + (count * 20) + 16
        boxY = 48
        boxH = math.min(wanted, 140)
    elseif nodeType == "check" then
        if self.mode == "diceResult" then boxY, boxH = 40, 150 else boxY, boxH = 56, 110 end
    end
    return boxX, boxY, boxW, boxH
end

function Dialog:update()
    gfx.clear(gfx.kColorWhite)

    if not self.node then
        gfx.drawTextAligned("(No node)", 192, 120, kTextAlignment.center)
        return
    end

    local nodeType = self.node.type
    local handler = DialogNodes[nodeType]

    local boxX, boxY, boxW, boxH = self:_panelLayout(nodeType)

    local wantsPanel = not (handler and handler.fullscreen)

    if wantsPanel then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(boxX, boxY, boxW, boxH, 8)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRoundRect(boxX, boxY, boxW, boxH, 8)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    if handler and handler.draw then
        handler.draw(self, boxX, boxY, boxW, boxH)
    else
        gfx.drawTextAligned("(Unknown node type)", 192, 120, kTextAlignment.center)
    end
end

-- ===== Input delegation =====
function Dialog:up()
    if not self.node then return end
    local h = DialogNodes[self.node.type]
    if h and h.up then h.up(self) end
end

function Dialog:down()
    if not self.node then return end
    local h = DialogNodes[self.node.type]
    if h and h.down then h.down(self) end
end

function Dialog:a()
    if not self.node then return end
    local h = DialogNodes[self.node.type]
    if h and h.a then h.a(self) end
end

function Dialog:b()
    -- Global cancel to menu (also clears any check UI state)
    self.mode = nil
    self.riskDiceCount = 0
    self.testResult = nil
    self.switch("menu")
end
