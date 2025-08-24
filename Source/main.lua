import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/timer"

import "scenes/menu"

local pd <const> = playdate
local gfx <const> = pd.graphics

-- Create scene instance
local activeScene = Menu()

function pd.update()
    gfx.setBackgroundColor(gfx.kColorWhite)
    gfx.setColor(gfx.kColorBlack)
    if activeScene and activeScene.update then activeScene:update() end
    pd.timer.updateTimers()
end

-- Input delegation
function pd.upButtonDown()    if activeScene.up then activeScene:up() end end
function pd.downButtonDown()  if activeScene.down then activeScene:down() end end
function pd.AButtonDown()     if activeScene.a then activeScene:a() end end
function pd.BButtonDown()     if activeScene.b then activeScene:b() end end
