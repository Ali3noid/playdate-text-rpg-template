-- main.lua
-- import "chapters/chapter2"

local pd <const> = playdate
local gfx <const> = pd.graphics


function init()
end

function pd.update()
    gfx.sprite.update()
end
