-- text rendering --

local lib = {}

local expect = require("cc.expect").expect
local resolve = require("rce.resolver")
local textures = require("rce.texture")

lib.path = "fonts/?.hex;rce/fonts/?.hex"

local function search(name)
  for ent in lib.path:gmatch("[^;]+") do
    ent = resolve(ent:gsub("%?", name))
    if fs.exists(ent) then
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
  assert(font[char], "font does not have character " .. char)
  for i, byte in ipairs(font[char]) do
    local I = i * scale - (scale - 1)
    for N = 7, 0, -1 do
      if bit32.band(byte, 2^N) ~= 0 then
        for n=0, scale-1, 1 do
          dat[n+I] = dat[n+I] or ""
          dat[n+I] = dat[n+I] .. fg:rep(scale)
        end
      else
        for n=0, scale-1, 1 do
          dat[n+I] = dat[n+I] or ""
          dat[n+I] = dat[n+I] .. bg:rep(scale)
        end
      end
    end
  end
  return dat
end

function lib.glyphs(font, str, fg, bg, scale)
  local rest
  for c in str:gmatch(".") do
    if not rest then
      rest = lib.glyph(font, c, fg, bg, scale)
    else
      local char = lib.glyph(font, c, fg, bg, scale)
      for i=1, #char, 1 do
        rest[i] = rest[i] .. char[i]
      end
    end
  end
  return rest
end

return lib
