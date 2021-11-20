-- main engine file --

local lib = {}
local expect = require("cc.expect").expect
local hud = require("rce.hud")
local input = require("rce.input")
local world = require("rce.world")
local physics = require("rce.physics")
local textures = require("rce.texture")

function lib.userenderer(id)
  lib.renderer = require("rce.renderers."..id)
end

lib.useHUDrenderer = hud.userenderer
lib.useinputscheme = input.useinputs

function lib.newstate()
  local state = {}
  lib.renderer.init(state)
  hud.init(state)
  textures.init()
  return state
end

-- preblit is a table of "drawable" textures generated by textures.todrawable
function lib.render(state, preblit)
  local start = os.epoch("utc")
  lib.renderer.renderFrame(state, preblit)
  hud.render()
  return os.epoch("utc") - start
end

lib.PLAYER_FORWARD = false
lib.PLAYER_BACKWARD = true
lib.PLAYER_LEFT = 0
lib.PLAYER_RIGHT = 1
lib.TURN_LEFT = false
lib.TURN_RIGHT = true

function lib.movePlayer(s, dir, speed)
  expect(1, s, "table")
  expect(3, speed, "number")
  local mdirX, mdirY = s.dirX, s.dirY
  local mdX2, mdY2 = mdirX, mdirY
  local offX, offY = 0.3, 0.3
  if dir == lib.PLAYER_LEFT or dir == lib.PLAYER_RIGHT then
    mdirX, mdirY = s.planeX, s.planeY
    mdX2, mdY2 = mdirX, mdirY
  end
  if dir == lib.PLAYER_BACKWARD or dir == lib.PLAYER_LEFT then
    mdirX, mdirY, offX, offY = -mdirX, -mdirY, -offX, -offY
  end
  if math.abs(mdX2) ~= mdX2 then offX = -offX end
  if math.abs(mdY2) ~= mdY2 then offY = -offY end

  local nposX = s.posX + mdirX * speed
  local nposY = s.posY + mdirY * speed

  -- old and new X and Y
  local oX = math.floor(s.posX + offX)
  local oY = math.floor(s.posY + offY)
  local nX = math.floor(nposX + offX)
  local nY = math.floor(nposY + offY)

  -- tiles used for collisions checking
  local tileA, tileB, tileC = world.gettile(s.world, oX, nY),
    world.gettile(s.world, nX, oY),
    world.gettile(s.world, nX, nY)
  if tileB == 0 or world.isdooropen(s.world, nX, oY) then
    s.posX = nposX
  end
  if tileA == 0 or world.isdooropen(s.world, oX, nY) then
    s.posY = nposY
  end
  if tileC == 0 or world.isdooropen(s.world, nX, nY) then
    s.posX = nposX
  end
end

function lib.turnPlayer(s, dir, speed)
  expect(1, s, "table")
  expect(3, speed, "number")
  local rot = speed
  if dir then rot = -rot end
  local oldDirX = s.dirX
  s.dirX = oldDirX * math.cos(rot) - s.dirY * math.sin(rot)
  s.dirY = oldDirX * math.sin(rot) + s.dirY * math.cos(rot)
  local oldPlaneX = s.planeX
  s.planeX = oldPlaneX * math.cos(rot) - s.planeY * math.sin(rot)
  s.planeY = oldPlaneX * math.sin(rot) + s.planeY * math.cos(rot)
end

return lib
