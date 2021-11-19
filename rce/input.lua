-- input module --

local lib = {}

lib.pressed = {}
lib.keys = {}

function lib.useinputs(name)
  lib.inputscheme = require("rce.inputschemes."..name)
end

function lib.tick()
  lib.inputscheme.tick(lib)
end

return lib
