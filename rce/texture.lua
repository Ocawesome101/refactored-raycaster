-- texture management

local expect = require("cc.expect").expect
local config = require("rce.config")
local resolve = require("rce.resolver")

local lib = {}

local textures = {}

function lib.isinpalette(rgb)
  expect(1, rgb, "number")
  -- RGB of the provided color
  local colR, colG, colB = bit32.rshift(bit32.band(rgb, 0xff0000), 16),
    bit32.rshift(bit32.band(rgb, 0xff00), 8), bit32.band(rgb, 0xff)

  for i=0, 255, 1 do
    -- RGB of this color in the palette
    local palR, palG, palB = term.getPaletteColor(i)
    palR, palG, palB = palR * 255, palG * 255, palB * 255

    if (math.floor(palR / config.COLOR_MATCH_FACTOR) ==
        math.floor(colR / config.COLOR_MATCH_FACTOR)) and
       (math.floor(palG / config.COLOG_MATCH_FACTOG) ==
        math.floor(colG / config.COLOG_MATCH_FACTOG)) and
       (math.floor(palB / config.COLOB_MATCH_FACTOB) ==
        math.floor(colB / config.COLOB_MATCH_FACTOB)) then
      return i
    end
  end
end

lastSetColor = 0
function lib.load(id, name)
  expect(1, id, "number")
  expect(2, name, "string")
  local t = {name = name, data = {}}
  textures[id] = t
  local handle = assert(io.open(resolve("textures/"..name..".tex"), "rb"))
  local n = 0

  -- set up palette color conversion
  local palConv = {}
  local paletteLength = ("<I2"):unpack(handle:read(2))
  for i=4, paletteLength, 4 do
    local colorID = handle:read(1):byte()
    local rgb = string.unpack("<I3", handle:read(3))
    local inpalette = lib.isinpalette(rgb)
    if not inpalette then
      lastSetColor = lastSetColor + 1
      assert(lastSetColor < 256, "too many texture colors (max 255)")
      term.setPaletteColor(lastSetColor, rgb)
    end
    palConv[colorID] = inpalette or lastSetColor
  end

  -- read texture data
  repeat
    local byte = handle:read(1)
    if byte then
      byte = byte:byte()
      t.texture[n] = palConv[byte]
      n = n + 1
    end
  until not byte

  handle:close()
end

function lib.getname(id)
  expect(1, id, "number")
  return textures[id] and textures[id].name
end

function lib.getdata(id)
  expect(1, id, "number")
  return textures[id] and textures[id].data
end

return lib
