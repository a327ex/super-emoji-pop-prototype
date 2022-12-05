Good ideas to port over:
  Objects that have certain mixins are added to global weak tables on creation, and those tables are updated automatically by the engine
  Draw commands with gfx, layer, z, etc so that the user doesn't need to separate between update and draw functions
  "layers" function and automatic canvas creation
