import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/timer"

import "scenes/menu"
import "scenes/dialog"

local pd <const> = playdate
local gfx <const> = pd.graphics

-- Active scene instance
local activeScene

-- Simple scene switcher handed to scenes via config
local function switchScene(name, opts)
    if activeScene and activeScene.leave then activeScene:leave() end

    if name == "menu" then
        activeScene = Menu({ switch = switchScene })
    elseif name == "dialog" then
        -- Pass through script, stats and inventory
        activeScene = Dialog({
            switch    = switchScene,
            script    = (opts and opts.script) or nil,
            stats     = (opts and opts.stats) or nil,
            inventory = (opts and opts.inventory) or nil
        })
    else
        error("Unknown scene: " .. tostring(name))
    end

    if activeScene and activeScene.enter then activeScene:enter() end
end

function pd.update()
    gfx.setBackgroundColor(gfx.kColorWhite)
    gfx.setColor(gfx.kColorBlack)
    if activeScene and activeScene.update then activeScene:update() end
    pd.timer.updateTimers()
end

-- Input delegation
function pd.upButtonDown()    if activeScene and activeScene.up then activeScene:up() end end
function pd.downButtonDown()  if activeScene and activeScene.down then activeScene:down() end end
function pd.AButtonDown()     if activeScene and activeScene.a then activeScene:a() end end
function pd.BButtonDown()     if activeScene and activeScene.b then activeScene:b() end end

-- Boot to menu
switchScene("menu")