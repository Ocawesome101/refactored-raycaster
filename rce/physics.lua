-- physics

local config = require("rce.config")

local lib = {}

-- rectangles are defined by two points
function lib.isinside(p, r)
  return p.x >= r.p1.x and p.x <= r.p2.x and p.y >= r.p1.y and p.y <= r.p2.y
end

-- returns whether any point in r1 is inside r2, or vice versa
function lib.overlaps(r1, r2)
  return lib.isinside(r1.p1, r2) or lib.isinside(r1.p2, r2) or
    lib.isinside(r2.p1, r1) or lib.isinside(r2.p2, r1)
end

-- convert a set of coordinates to a rectangle
function lib.coordstorect(x, y)
  return {
    p1 = {
      x - config.PHYSICS_HITBOX_RADIUS,
      y - config.PHYSICS_HITBOX_RADIUS
    },
    p2 = {
      x + config.PHYSICS_HITBOX_RADIUS,
      y + config.PHYSICS_HITBOX_RADIUS
    }
  }
end

return lib
