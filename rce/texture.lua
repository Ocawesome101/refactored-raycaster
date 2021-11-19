-- texture management

local expect = require("cc.expect").expect
local config = require("rce.config")
local resolve = require("rce.resolver")

local lib = {}

local textures = {}

local palette = {}
function lib.isinpalette(rgb)
  expect(1, rgb, "number")
  -- RGB of the provided color
  local colR, colG, colB = bit32.rshift(bit32.band(rgb, 0xff0000), 16),
    bit32.rshift(bit32.band(rgb, 0x00ff00), 8), bit32.band(rgb, 0x0000ff)

  for i=0, #palette, 1 do
    if not palette[i] then break end
    -- RGB of this color in the palette
    local palR, palG, palB = bit32.rshift(bit32.band(palette[i], 0xff0000), 16),
      bit32.rshift(bit32.band(palette[i], 0x00ff00), 8),
      bit32.band(palette[i], 0x0000ff)

    if (math.floor(palR / config.COLOR_MATCH_FACTOR) ==
        math.floor(colR / config.COLOR_MATCH_FACTOR)) and
       (math.floor(palG / config.COLOR_MATCH_FACTOR) ==
        math.floor(colG / config.COLOR_MATCH_FACTOR)) and
       (math.floor(palB / config.COLOR_MATCH_FACTOR) ==
        math.floor(colB / config.COLOR_MATCH_FACTOR)) then
      return i
    end
  end
end

local lastSetColor = 0
function lib.addtopalette(rgb)
  local idx = lib.isinpalette(rgb)
  if idx then return idx end
  term.setPaletteColor(lastSetColor, rgb)
  palette[lastSetColor] = rgb
  lastSetColor = lastSetColor + 1
  return lastSetColor
end

function lib.load(id, name)
  expect(1, id, "number")
  expect(2, name, "string")
  local t = {name = name, data = {}}
  textures[id] = t
  local handle = assert(io.open(resolve("textures/"..name..".tex"), "rb"))

  -- set up palette color conversion
  local palConv = {}
  local paletteLength = ("<I2"):unpack(handle:read(2))
  for i=4, paletteLength, 4 do
    local colorID = handle:read(1):byte()
    local rgb = string.unpack("<I3", handle:read(3))
    local inpalette = lib.isinpalette(rgb)
    if not inpalette then
      assert(lastSetColor < 256, "too many texture colors (max 255)")
      lib.addtopalette(rgb)
    end
    palConv[colorID] = inpalette or lastSetColor
  end

  local n = 0
  -- read texture data
  repeat
    local byte = handle:read(1)
    if byte then
      byte = byte:byte()
      t.data[n] = palConv[byte]
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

-- convert to a format directly drawable on screen
function lib.todrawable(id, scale)
  expect(1, id, "number")
  expect(2, scale, "number")
  
  if not textures[id] then return nil end
  local dat = textures[id].data
  local draw = {}

  for y = config.TEXTURE_HEIGHT - 1, 0, -1 do
    local lineOffset, line = 0, ""

    for x = 0, config.TEXTURE_WIDTH - 1, 1 do
      local idx = config.TEXTURE_WIDTH * y + x
      if dat[idx] == 0 then
        line = line .. string.char(dat[idx]):rep(scale)
      elseif dat[idx] then
        lineOffset = x * scale
      end
    end

    if #line > 0 then
      for i=1, scale, 1 do
        draw[#draw+1] = {config.TEXTURE_WIDTH-lineOffset, line}
      end
    end
  end

  return draw
end

return lib
