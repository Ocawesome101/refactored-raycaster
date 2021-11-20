-- world loading and management --

local expect = require("cc.expect").expect
local config = require("rce.config")
local resolve = require("rce.resolver")
local textures = require("rce.texture")
local lib = {}

function lib.load(state, file)
  expect(1, state, "table")
  expect(2, file, "string")
  local w = {world = {}, doors = {}, sprites = {}}

  local handle = assert(io.open(resolve(file), "rb"))
  local mapWidth, mapHeight = ("<I2I2"):unpack(handle:read(4))
  local data = handle:read("a")
  handle:close()

  repeat
    local texID = ("<s1"):unpack(data)
    if texID and #texID > 0 then
      data = data:sub(2 + #texID)
      local id = texID:sub(1,1):byte()
      texID = texID:sub(2)
      textures.load(id, texID)
    else
      texID = nil
    end
  until not texID

  data = data:sub(2) -- remove trailing null byte left over from
                     -- texture palette data

  local mapY, mapX = 0, 0
  w.world[mapY] = {}
  w.doors[mapX] = {}

  for byte in data:gmatch(".") do
    byte = byte:byte()
    local door = bit32.band(byte, 0x80) ~= 0
    local sprite = bit32.band(byte, 0x40) ~= 0
    local tile = bit32.band(byte, 0x3F)

    -- a tile cannot be both a door and a sprite
    if door and sprite then door, sprite = false, false end
    
    if mapX >= mapWidth then
      mapY = mapY + 1
      mapX = 0
      w.world[mapY] = w.world[mapY] or {}
    end

    w.world[mapY][mapX] = 0
    if door then
      w.doors[mapY] = w.doors[mapY] or {}
      -- fields in this table:
      -- distance sideways, distance inwards, min inward distance, is moving
      w.doors[mapY][mapX] = {0, textures.getname(tile) == "door" and 0.5 or 0,
        textures.getname(tile) == "door" and 0.5 or 0}
    end

    if sprite then
      -- the minimum fields here are {mapX, mapY, texID}
      w.sprites[#w.sprites+1] = {mapX + 0.5, mapY + 0.5, tile}
    else
      w.world[mapY][mapX] = tile
    end
    
    mapX = mapX + 1
  end

  state.world = w
end

function lib.gettile(w, x, y)
  expect(1, w, "table")
  expect(2, x, "number")
  expect(3, y, "number")
  return w.world[y] and w.world[y][x]
end

function lib.isdoor(w, x, y)
  expect(1, w, "table")
  expect(2, x, "number")
  expect(3, y, "number")
  return not not (w.doors[y] and w.doors[y][x])
end

function lib.doorstate(w, x, y)
  expect(1, w, "table")
  expect(2, x, "number")
  expect(3, y, "number")
  if not lib.isdoor(w, x, y) then return end
  return w.doors[y][x]
end

function lib.isdooropen(w, x, y)
  expect(1, w, "table")
  expect(2, x, "number")
  expect(3, y, "number")
  if not lib.isdoor(w, x, y) then return end
  return w.doors[y][x][1] >= config.DOOR_OPEN_THRESHOLD
end

return lib
