-- buffered rendering for the craftos-pc terminal --

local config = require("rce.config")

local drawbuf = {}
local w, h = term.getSize(2)
h = h - config.HUD_HEIGHT

local lib = {}

function lib.setPixel(x, y, color)
  color = string.char(color)
  if #drawbuf[y] < w then
    drawbuf[y] = drawbuf[y] .. color
  else
    drawbuf[y] = drawbuf[y]:sub(0,x) .. color .. drawbuf[y]:sub(x+2)
  end
end

-- modes:
--  1: drawbuf is literally empty
--  2: drawbuf is full of NULLs (slower to use)
function lib.initNewFrame(mode)
  if mode == 1 then
    for i=0, h - 1, 1 do
      drawbuf[i] = ""
    end
  elseif mode == 2 then
    for i=0, h - 1, 1 do
      drawbuf[i] = ("\0"):rep(w - 1)
    end
  else
    error("invalid mode (got " .. mode .. ")")
  end
end

function lib.drawFrame()
  term.drawPixels(0, 0, drawbuf)
end

function lib.init(state)
  state.width = w
  state.height = h
  term.setGraphicsMode(2)
end

return lib
