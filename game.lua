-- game logic --

local rce = require("rce")
local input = require("rce.input")
local world = require("rce.world")

local worlds = {
  {text = "Map 01: Awakening", map = "maps/map1.map"},
  {text = "Map 02: Preparation", map = "maps/map02.map"},
  {text = "Map 03: Slaughter", map = "maps/map03.map"}
}

rce.userenderer("raycast")
rce.useinputscheme("cc")
local state = rce.newstate()

world.load(state, "maps/map01.map")

local function forEachSprite(func)
  for i, sprite in ipairs(state.world.sprites) do
    func(i, sprite)
  end
end

while true do
  rce.render(state)
  local exit = input.tick()
  if exit then break end
end
