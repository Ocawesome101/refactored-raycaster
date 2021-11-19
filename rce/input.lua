-- input module --

local lib = {}

lib.pressed = {}
lib.keys = {}

function lib.useinputs(name)
  lib.inputscheme = require("rce.inputschemes."..name)
  lib.keys = lib.inputscheme.keys
end

function lib.tick()
  return lib.inputscheme.tick(lib)
end

return lib
