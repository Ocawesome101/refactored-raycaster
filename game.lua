-- game logic --

local rce = require("rce")
local input = require("rce.input")
local world = require("rce.world")
local physics = require("rce.physics")

local worlds = {
  {text = "Map 01: Awakening", map = "maps/map1.map"},
  {text = "Map 02: Preparation", map = "maps/map02.map"},
  {text = "Map 03: Slaughter", map = "maps/map03.map"}
}

rce.userenderer("raycast")
rce.useinputscheme("cc")
local state = rce.newstate()

textures.load(512, "enemy-broken")
textures.load(513, "projectile")
textures.load(514, "minigun01")
textures.load(515, "minigun02")
textures.load(516, "rocket")
textures.load(517, "gunfire")

local drawables = {
  gunfire = textures.todrawable(517, 2)
  minigun = {
    textures.todrawable(514, 2),
    textures.todrawable(515, 2),
  },
  rocket = textures.todrawable(516, 2),
  -- TODO: unique pistol graphic
  pistol = textures.todrawable(516)
}

world.load(state, "maps/map01.map")

local function forEachSprite(func, matches)
  for i, sprite in ipairs(state.world.sprites) do
    if (not matches) or sprite[3] == matches then
      func(i, sprite)
    end
  end
end

local lastShot, nextShot = 0, 0
while true do
  local preblit, gun = {}
  if os.epoch("utc") - lastShot <= 100 then
    preblit[1] = gunfire
  end
  if gun then
    preblit[#preblit+1] = {0,gun}
  end
  local frametime = rce.render(state, preblit)
  local exit = input.tick()
  if exit then break end

  if input.pressed[input.keys.w] then
  end
end
