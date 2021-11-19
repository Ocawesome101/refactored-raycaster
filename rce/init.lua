-- main engine file --

local lib = {}
local input = require("rce.input")

function lib.userenderer(id)
  lib.renderer = require("rce.renderers."..id)
end

lib.useinputscheme = input.useinputs

function lib.newstate()
  local state = {}
  lib.renderer.init(state)
  return state
end

function lib.render(state)
  lib.renderer.renderFrame(state)
end

return lib
