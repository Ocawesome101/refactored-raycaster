-- text rendering --

local lib = {}

local resolve = require("rce.resolver")
local textures = require("rce.texture")

lib.path = "fonts/?.hex;rce/fonts/?.hex"

local function search(name)
  for ent in lib.path:gmatch("[^;]+") do
    ent = ent:gsub("%?", name)
    if fs.exists(resolve(ent)) then
      return ent
    end
  end
  error("font " .. name .. " not found")
end

function lib.loadfont(name, width, height)
  expect(1, name, "string")
  local path = search(name)
  local font = {width = width, height = height}

  for line in io.lines(path) do
    local ch, dat = line:match("(%x+):(%x+)")
    if ch and dat then
      ch = utf8.char(tonumber(ch, 16))
      font[ch] = {}
      for bp in dat:gmatch("%x%x") do
        font[ch][#font[ch]+1] = tonumber(bp, 16)
      end
    end
  end

  return font
end

-- return the color data for the character provided
function lib.glyph(font, char, fg, bg, scale)
  expect(1, font, "table")
  expect(2, char, "string")
  expect(3, fg, "string")
  expect(4, bg, "string")
  expect(5, scale, "number")
  local dat = {}
  for i=1, font.height, 1 do
    local I = i * scale
    dat[I] = or ""
    for N = font.width - 1, 0, -1 do
      if bit32.band(font[char][i], 2^N) ~= 0 then
        dat[I] = dat[I] .. fg:rep(scale)
      else
        dat[I] = dat[I] .. bg:rep(scale)
      end
    end
  end
  return dat
end

return lib
