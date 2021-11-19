-- HUD stuff --

local text = require("rce.text")
local config = require("rce.config")
local textures = require("rce.texture")

local font = text.loadfont(config.HUD_FONT, config.HUD_FONT_WIDTH,
  config.HUD_FONT_HEIGHT)

local lib = {}
local elements = {}

local renderer

local fg, bg
local dirty = false
function lib.render()
  if dirty then
    if not fg then fg = string.char(textures.addtopalette(0xFFFFFF)) end
    if not bg then bg = string.char(textures.addtopalette(0x003366)) end
    renderer.hudinit(nil, bg)
    for i=1, #elements, 1 do
      local lines = text.glyphs(font, elements[i].text, fg, bg,
        elements[i].scale)
      local line = 0
      for y=elements[i].y, elements[i].y+#lines-1, 1 do
        line = line + 1
        renderer.hudSetPixels(elements[i].x, y, lines[line])
      end
    end
  end
  renderer.hudDraw()
end

function lib.addElement(x, y, e, s)
  dirty = true
  elements[#elements + 1] = {x = x, y = y, text = e, scale = s or
    config.HUD_SCALE}
  return #elements
end

function lib.updateElement(id, t)
  if not elements[id] then return end
  dirty = true
  elements[id].text = t
end

function lib.userenderer(name)
  renderer = require("rce.renderers."..name)
end

function lib.init()
  renderer.hudinit()
end

return lib
