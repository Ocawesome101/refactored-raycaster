-- game logic --

local rce = require("rce")
local hud = require("rce.hud")
local input = require("rce.input")
local world = require("rce.world")
local physics = require("rce.physics")
local config = require("rce.config")
local textures = require("rce.texture")

local playerHealth = 100
local weapon = "pistol"

local worlds = {
  {text = "Map 01: Awakening", map = "maps/map1.map"},
  {text = "Map 02: Preparation", map = "maps/map02.map"},
  {text = "Map 03: Slaughter", map = "maps/map03.map"}
}

local weapons = {
  "pistol",
  pistol = {
    obtained = true,
    maxDamage = 20,
    shotInterval = 750,
    ammo = "basic",
    projectile = "hitscan"
  },
  "minigun",
  minigun = {
    obtained = false,
    maxDamage = 5,
    shotInterval = 50,
    ammo = "basic",
    projectile = "hitscan"
  },
  "rocket",
  rocket = {
    obtained = false,
    maxDamage = 120,
    shotInterval = 2000,
    ammo = "rocket",
    projectile = "fireball"
  }
}

local ammo = {
  basic = 128,
  rocket = 0
}

local items = {
}

rce.userenderer("raycast")
rce.useHUDrenderer("ccpc_term_buffered")
rce.useinputscheme("cc")
local state = rce.newstate()

textures.load(512, "enemy-broken")
textures.load(513, "projectile")
textures.load(514, "minigun01")
textures.load(515, "minigun02")
textures.load(516, "rocket")
textures.load(517, "gunfire")

hud.addElement(2, 2, "HEALTH: " .. playerHealth, 1)
hud.addElement(2, 8, "WEAPON: " .. weapon:upper(), 1)
hud.addElement(128, 2, "AMMO: " .. ammo[weapons[weapon].ammo], 2)

local drawables = {
  gunfire = textures.todrawable(517, config.HUD_SCALE),
  minigun = {
    textures.todrawable(514, config.HUD_SCALE),
    textures.todrawable(515, config.HUD_SCALE),
  },
  rocket = textures.todrawable(516, config.HUD_SCALE),
  -- TODO: unique pistol graphic, not just downscaled rocket
  pistol = textures.todrawable(516, math.floor(config.HUD_SCALE / 2))
}

world.load(state, worlds[1].map)

local function forEachSprite(func, matches)
  for i, sprite in ipairs(state.world.sprites) do
    if (not matches) or sprite[3] == matches then
      func(i, sprite)
    end
  end
end

local doorMoveDuration = math.floor(config.ANIMATION_DURATION / 4)
local doorOpenDuration = math.floor(config.ANIMATION_DURATION / 2)

local lastShot, nextShot = 0, 0
while true do
  local time = os.epoch("utc")
  local preblit, gun = {}
  if time - lastShot <= 100 then
    preblit[1] = {weapon == "pistol" and 0 or (8*config.HUD_SCALE),
      drawables.gunfire}
  end
  if weapon == "pistol" then gun = drawables.pistol
  elseif weapon == "minigun" then
    local idx
    if nextShot > time then
      idx = time % 100 >= 50 and 1 or 2
    else
      idx = 1
    end
    gun = drawables.minigun[idx]
  elseif weapon == "rocket" then gun = drawables.rocket end
  if gun then
    preblit[#preblit+1] = {0,gun}
  end
  local frametime = rce.render(state, preblit)
  local exit = input.tick()
  if exit then break end

  if input.pressed[input.keys.one] then
    if weapons[weapons[1]].collected then
      weapon = weapons[weapons[1]]
      hud.updateElement(hudweapon, weapon)
    end
  elseif input.pressed[input.keys.two] then
    if weapons[weapons[2]].collected then
      weapon = weapons[weapons[2]]
      hud.updateElement(hudweapon, weapon)
    end
  elseif input.pressed[input.keys.three] then
    if weapons[weapons[3]].collected then
      weapon = weapons[weapons[3]]
      hud.updateElement(hudweapon, weapon)
    end
  end

  local moveSpeed, rotSpeed = frametime * 0.007, frametime * 0.003

  if input.pressed[input.keys.space] then
    local dist, hit, mx, my = rce.renderer.cast(math.floor(state.width/2),state)
    if dist < 2 and world.isdoor(state.world, mx, my) then
      local dst = world.doorstate(state.world, mx, my)
      dst[4] = true
      dst[5] = dst[5] or time
    end
  end

  for y, col in pairs(state.world.doors) do
    for x, door in pairs(col) do
      if door[4] then
        if time - door[5] > doorOpenDuration + doorMoveDuration then
          door[1] = physics.lerp(1, 0, doorMoveDuration,
            time - door[5] - doorOpenDuration - doorMoveDuration)
          door[2] = physics.lerp(door[3], 0.5, doorMoveDuration,
            time - door[5] - doorOpenDuration - doorMoveDuration)
          if time - door[5] > config.ANIMATION_DURATION + 2000 then
            door[4] = false
            door[5] = nil
          end
        else
          door[1] = physics.lerp(0, 1, doorMoveDuration, time - door[5])
          door[2] = physics.lerp(door[3], 0.5, doorMoveDuration, time - door[5])
          door[1] = math.min(1, door[1] + 0.1 * moveSpeed)
          door[2] = math.min(0.5, door[2] + 0.1 * moveSpeed)
        end
      end
    end
  end

  -- this is below the spacebar check
  if (input.pressed[input.keys.w] or input.pressed[input.keys.s]) and
     (input.pressed[input.keys.a] or input.pressed[input.keys.d]) then
    moveSpeed = moveSpeed * 0.8
  end

  if input.pressed[input.keys.w] then
    rce.movePlayer(state, rce.PLAYER_FORWARD, moveSpeed)
  end
  if input.pressed[input.keys.s] then
    rce.movePlayer(state, rce.PLAYER_BACKWARD, moveSpeed)
  end
  if input.pressed[input.keys.a] then
    rce.movePlayer(state, rce.PLAYER_LEFT, moveSpeed)
  end
  if input.pressed[input.keys.d] then
    rce.movePlayer(state, rce.PLAYER_RIGHT, moveSpeed)
  end
  if input.pressed[input.keys.left] then
    rce.turnPlayer(state, rce.TURN_LEFT, rotSpeed)
  end
  if input.pressed[input.keys.right] then
    rce.turnPlayer(state, rce.TURN_RIGHT, rotSpeed)
  end
end

