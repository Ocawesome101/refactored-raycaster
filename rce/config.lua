return {
  -- What the RGB values of a color are divided by during color
  -- comparison while loading textures.
  -- Default: 16
  COLOR_MATCH_FACTOR = 16,
  -- Controls raycaster line height.  Can be useful for making things
  -- look more square.
  -- Default: 1.1
  LINE_HEIGHT_MULTIPLIER = 1.1,
  -- The width and height of texture.  **ALL** texture files MUST be
  -- these dimensions.
  -- Defaults: 64, 64
  TEXTURE_WIDTH = 64,
  TEXTURE_HEIGHT = 64,
  -- How far a door must be open before it is considered open.
  -- Default: 0.3
  DOOR_OPEN_THRESHOLD = 0.3,
  -- The radius of a hitbox used when calculating sprite collisions
  -- Default: 0.3
  PHYSICS_HITBOX_RADIUS = 0.3,
  -- The height of the heads-up display, in pixels.
  -- Default: 20
  HUD_HEIGHT = 20,
  -- The scale of the heads-up display.
  -- Default: 2
  HUD_SCALE = 2,
  -- The font to use for the heads-up display.  Must be the name of a
  -- hexfont in the fonts/ or rce/fonts/ folder;  for example, a
  -- value of 5x5 here points to fonts/5x5.hex.
  -- Default: 5x5
  HUD_FONT = "5x5",
  -- The width and height of the HUD font.  **Must be correct, or chaos
  -- will ensue with font renering.**
  -- Defaults: 5, 5
  HUD_FONT_WIDTH = 5,
  HUD_FONT_HEIGHT = 5,
  -- The field-of-view of any 3D renderers.
  -- Default: 66
  FOV = 66
}
