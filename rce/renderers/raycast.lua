-- raycasting renderer --

local expect = require("cc.expect").expect
local config = require("rce.config")
local textures = require("rce.texture")
local world = require("rce.world")
local rdr

local lib = {}

local col_ceil
local col_floor

local function cast(x, state, render)
  local posX, posY, dirX, dirY, planeX, planeY =
    state.posX, state.posY, state.dirX, state.dirY, state.planeX, state.planeY
  local map = state.world
  local w = state.width
  local h = state.height

  local mapX, mapY = math.floor(posX), math.floor(posY)
  local cameraX = 2 * x / w - 1
  local rayDirX = dirX + planeX * cameraX
  local rayDirY = dirY + planeY * cameraX

  local sideDistX, sideDistY

  local deltaDistX = (rayDirX == 0) and 1e30 or math.abs(1 / rayDirX)
  local deltaDistY = (rayDirY == 0) and 1e30 or math.abs(1 / rayDirY)
  local perpWallDist

  local stepX, stepY

  local hit = false
  local side

  if rayDirX < 0 then
    stepX = -1
    sideDistX = (posX - mapX) * deltaDistX
  else
    stepX = 1
    sideDistX = (mapX + 1 - posX) * deltaDistX
  end

  if rayDirY < 0 then
    stepY = -1
    sideDistY = (posY - mapY) * deltaDistY
  else
    stepY = 1
    sideDistY = (mapY + 1 - posY) * deltaDistY
  end

  local pmX, pmY, door
  while not hit do
    if sideDistX < sideDistY then
      sideDistX = sideDistX + deltaDistX
      mapX = mapX + stepX
      side = 0
    else
      sideDistY = sideDistY + deltaDistY
      mapY = mapY + stepY
      side = 1
    end

    pmX, pmY = mapX, mapY
    if not world.gettile(map, mapX, mapY) then
      hit = 0
    elseif world.isdoor(map, mapX, mapY) then
      local doorState = world.doorstate(map, mapX, mapY)
      local distSide = doorState[1]
      local distIn = doorState[2]

      -- calculations taken from https://gist.github.com/Powersaurus/ea9a1d57fb30ea166e7e48762dca0dde
      local rdx2 = rayDirX*rayDirX
      local rdy2 = rayDirY*rayDirY
      local trueDeltaX = math.sqrt(1 + rdy2/rdx2)
      local trueDeltaY = math.sqrt(1 + rdx2/rdy2)

      local mapX2, mapY2 = mapX, mapY
      if posX < mapX2 then mapX2 = mapX2 - 1 end
      if posY > mapY2 then mapY2 = mapY2 + 1 end

      if side == 0 then
        local rayMult = ((mapX2 - posX) + 1) / rayDirX
        local rye = posY + rayDirY * rayMult

        local trueStepY = math.sqrt(trueDeltaX*trueDeltaX-1)
        local halfStepY = rye + (stepY*trueStepY) * distIn
        if math.floor(halfStepY) == mapY and halfStepY - mapY > distSide then
          hit = world.gettile(map, mapX, mapY)
          pmX = pmX + stepX * distIn
          door = distSide
        end
      else
        local rayMult = (mapY2 - posY) / rayDirY
        local rxe = posX + rayDirX * rayMult
        local trueStepX = math.sqrt(trueDeltaY*trueDeltaY-1)
        local halfStepX = rxe + (stepX*trueStepX) * distIn
        if math.floor(halfStepX) == mapX and halfStepX - mapX > distSide then
          hit = world.gettile(map, mapX, mapY)
          pmY = pmY + stepY * distIn
          door = distSide
        end
      end
    elseif world.gettile(map, mapX, mapY) ~= 0 then
      hit = world.gettile(map, mapX, mapY)
    end
  end

  if not door then
    door = 0
    -- use faster perpWallDist calculation when the ray didn't hit a door
    if side == 0 then perpWallDist = sideDistX - deltaDistX
                 else perpWallDist = sideDistY - deltaDistY end
  else
    if side == 0 then
      perpWallDist = (pmX - posX + (1 - stepX) / 2) / rayDirX
    else
      perpWallDist = (pmY - posY + (1 - stepY) / 2) / rayDirY
    end
  end

  if render then
    local lineHeight = math.floor(h / perpWallDist *
      config.LINE_HEIGHT_MULTIPLIER)

    local drawStart = math.max(0, -lineHeight / 2 + h / 2)
    local drawEnd = math.min(h - 1, lineHeight / 2 + h / 2)

    local tex = textures.getdata(hit)
    if not tex then return end

    local wallX
    if side == 0 then wallX = posY + perpWallDist * rayDirY
    else wallX = posX + perpWallDist * rayDirX end
    wallX = wallX - door
    wallX = wallX - math.floor(wallX)

    local texX = math.floor(wallX * config.TEXTURE_WIDTH)
    if (side == 0 and rayDirX > 0) or (side == 1 and rayDirY < 0) then
        texX = config.TEXTURE_WIDTH - texX - 1 end

    local step = config.TEXTURE_HEIGHT / lineHeight
    local texPos = (drawStart - h / 2 + lineHeight / 2) * step

    for i=0, h - 1, 1 do
      local color = col_floor
      if (i >= drawStart and i < drawEnd) then
        local texY = bit32.band(math.floor(texPos), config.TEXTURE_HEIGHT - 1)
        color = tex[config.TEXTURE_HEIGHT * texY + texX] or 255
        texPos = texPos + step
      elseif i < drawStart then
        color = col_ceil
      end
      rdr.setPixel(x, i, color)
    end
  end

  return perpWallDist, hit, math.floor(mapX), math.floor(mapY)
end

lib.cast = cast

function lib.renderFrame(state, preblit)
  expect(1, state, "table")

  local w = state.width
  local h = state.height
  local sprites = state.world.sprites
  rdr.initNewFrame(1)
  local posX, posY, dirX, dirY, planeX, planeY =
    state.posX, state.posY, state.dirX, state.dirY, state.planeX, state.planeY

  local zBuffer = {}
  for x = 0, w - 1, 1 do
    zBuffer[x] = cast(x, state, true)
  end

  -- sprite rendering
  local spriteOrder = {}
  local spriteDistance = {}

  for i=1, #sprites, 1 do
    local s = sprites[i]
    spriteOrder[i] = i
    spriteDistance[i] = ((posX - s[1]) * (posX - s[1])
      + (posY - s[2]) * (posY - s[2]))
  end
  table.sort(spriteOrder, function(a, b)
    return (spriteDistance[a] or 0) > (spriteDistance[b] or 0)
  end)

  for i=1, #spriteOrder, 1 do
    local s = sprites[spriteOrder[i]]
    local spriteX = s[1] - posX
    local spriteY = s[2] - posY

    local invDet = 1 / (planeX * dirY - dirX * planeY)

    local transformX = invDet * (dirY * spriteX - dirX * spriteY)
    local transformY = invDet * (-planeY * spriteX + planeX * spriteY)

    local spriteScreenX = math.floor((w / 2) * (1 + transformX / transformY))

    local spriteHeight = math.abs(math.floor(h / transformY
      * config.LINE_HEIGHT_MULTIPLIER))
    local spriteWidth = spriteHeight-- / config.LINE_HEIGHT_MULTIPLIER

    local drawStartY = math.max(0, -spriteHeight / 2 + h / 2)
    local drawEndY = math.min(h - 1, spriteHeight / 2 + h / 2)

    local drawStartX = math.max(0, -spriteWidth / 2 + spriteScreenX)
    local drawEndX = math.min(w - 1, spriteWidth / 2 + spriteScreenX)

    local dof = h / 2 + spriteHeight / 2
    local sof = (-spriteWidth / 2 + spriteScreenX)
    local twdsw = config.TEXTURE_WIDTH / spriteWidth
    for stripe = math.floor(drawStartX), drawEndX, 1 do
      local texX = math.floor((stripe - sof) * twdsw) % config.TEXTURE_WIDTH

      if transformY > 0 and stripe > 0 and stripe < w
          and transformY < zBuffer[stripe] then
        for y = math.ceil(drawStartY), drawEndY, 1 do
          local d = y - dof
          local texY = math.floor((d * config.TEXTURE_HEIGHT)/spriteHeight)
            % config.TEXTURE_WIDTH
          local texidx = config.TEXTURE_WIDTH * texY + texX
          local color = textures.getdata(s[3])[texidx]
          if color ~= 0 then
            rdr.setPixel(stripe, y, color)
          end
        end
      end
    end
  end

  if preblit then
    for i=1, #preblit, 1 do
      local yoff, img = preblit[i][1], preblit[i][2]
      local w2 = math.floor(w / 2)
      for l=0, #img, 1 do
        if img[l] then
          local y = h - i - yoff
          rdr.setPixels(w2 - img[l][1], y, img[l][2])
        end
      end
    end
  end

  rdr.drawFrame()
end

lib.setPaletteColor = term.setPaletteColor

function lib.init(state)
  state.posX = state.posX or 3
  state.posY = state.posY or 3
  state.dirX = 0
  state.dirY = 1
  state.planeX = config.FOV/100
  state.planeY = 0
  rdr = require("rce.renderers.ccpc_term_buffered")
  rdr.init(state)
  col_ceil = textures.addtopalette(0x383838)
  col_floor = textures.addtopalette(0x707070)
end

return lib
