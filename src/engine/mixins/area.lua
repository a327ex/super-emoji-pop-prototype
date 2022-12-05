local mode_k = {__mode = 'k'}

-- Mixin that creates a collider area and enables collision detection for its game object.
-- This is in contrast with the "collider" mixin, which uses box2d and thus handles collision resolution.
-- If all you need is collision detection and very simple resolution (i.e. player shouldn't go through solid walls) then this is the mixin you should use.
-- Possible shapes and attributes:
--  'rectangle', width, height
--  'polygon', vertices
--    Polygon vertices are defined in local coordinates, with self.x, self.y being the center of the polygon
--    This is the center that the polygon will be rotated around
--    If the polygon will never be rotated and/or is static, then just keep self.x, self.y equal to 0
--  'circle', radius
--  'line', x1, y1, x2, y2
--  'point'
--
--  If this mixin is added after a text/sprite and has no arguments passed in, then it will be automatically set to be a rectangle with the dimensions of the text/sprite.
area = class:use()
function area:area(shape_type, a, b, c, d, e)
  self.shape_type = shape_type
  if self.shape_type == 'point' then
    self.w, self.h = 1, 1
  elseif self.shape_type == 'line' then
    self.x1, self.y1, self.x2, self.y2 = a, b, c, d
    self.x, self.y = (self.x1 + self.x2)*0.5, (self.y1 + self.y2)*0.5
    self.w, self.h = math.abs(self.x1 - self.x2), math.abs(self.y1 - self.y2)
  elseif self.shape_type == 'rectangle' then
    self.w, self.h = a, b
    self.vertices = math.to_rectangle_vertices(self.x - self.w*0.5, self.y - self.h*0.5, self.x + self.w*0.5, self.y + self.h*0.5)
    print(unpack(self.vertices))
  elseif self.shape_type == 'polygon' then
    self.local_vertices = a
    self.vertices = {}
    for i = 1, #self.local_vertices, 2 do
      table.insert(self.vertices, self.x + self.local_vertices[i])
      table.insert(self.vertices, self.y + self.local_vertices[i+1])
    end
    self.w, self.h = math.get_polygon_size(unpack(self.vertices))
  elseif self.shape_type == 'circle' then
    self.rs = a
    self.w, self.h = 2*self.rs, 2*self.rs
  end

  self.previous_collisions = {}
  setmetatable(self.previous_collisions, {__mode = 'k'})
  self.collisions = {}
  setmetatable(self.collisions, {__mode = 'k'})
end

function area:update_vertices(dt)
  -- Rectangles and polygons need their vertices constantly updated so collision calculations are correct
  -- Rotation applies to rectangles and polygons only and are based around their center or origin point if defined
  if self.shape_type == 'rectangle' then
    self.vertices = math.to_rectangle_vertices(self.x - self.w/2 - (self.ox or 0), self.y - self.h/2 - (self.oy or 0), self.x + self.w/2 - (self.ox or 0), self.y + self.h/2 - (self.oy or 0))
    for i = 1, #self.vertices, 2 do
      self.vertices[i], self.vertices[i+1] = math.rotate_point(self.vertices[i], self.vertices[i+1], self.r, self.x, self.y)
    end
  elseif self.shape_type == 'polygon' then
    for i = 1, #self.local_vertices, 2 do
      self.vertices[i] = self.x + self.local_vertices[i] - (self.ox or 0)
      self.vertices[i+1] = self.y + self.local_vertices[i+1] - (self.oy or 0)
    end
    for i = 1, #self.vertices, 2 do
      self.vertices[i], self.vertices[i+1] = math.rotate_point(self.vertices[i], self.vertices[i+1], self.r, self.x, self.y)
    end
    self.w, self.h = math.get_polygon_size(unpack(self.vertices))
  end
end

function area:area_draw(layer, color, line_width, z, fixed)
  set_color(color or colors.fg[0])
  if self.shape_type == 'point' then
    table.insert(draw_commands, {type = 'rectangle', args = {self.x, self.y, 1, 1, 0, 0, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
  elseif self.shape_type == 'line' then
    table.insert(draw_commands, {type = 'line', args = {self.x1, self.y1, self.x2, self.y2, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
  elseif self.shape_type == 'rectangle' or self.shape_type == 'polygon' then
    table.insert(draw_commands, {type = 'polygon', args = {self.vertices, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
  elseif self.shape_type == 'circle' then
    table.insert(draw_commands, {type = 'circle', args = {self.x, self.y, self.rs, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
  end
end

-- Returns a table with .enter, .active and .leave booleans.
-- If .enter is true then this object has entered collision with the other in this frame.
-- If .leave is true then this object has left collision with the other in this frame.
-- If .active is true then this object is colliding with the other in this frame.
-- .enter and .leave will always only be true for 1 frame, while .active might be true for multiple frames.
function area:is_colliding_with(other)
  local colliding = false
  if self.shape_type == 'point' then
    if other.shape_type == 'point' then
      colliding = math.distance(self.x, self.y, other.x, other.y) <= 1e-6
    elseif other.shape_type == 'line' then
      colliding = math.point_line(self.x, self.y, other.x1, other.y1, other.x2, other.y2)
    elseif other.shape_type == 'rectangle' or other.shape_type == 'polygon' then
      colliding = math.point_polygon(self.x, self.y, unpack(other.vertices))
    elseif other.shape_type == 'circle' then
      colliding = math.point_circle(self.x, self.y, other.x, other.y, other.rs)
    end
  elseif self.shape_type == 'line' then
    if other.shape_type == 'point' then
      colliding = math.point_line(other.x, other.y, self.x1, self.y1, self.x2, self.y2)
    elseif other.shape_type == 'line' then
      colliding = math.line_line(self.x1, self.y1, self.x2, self.y2, other.x1, other.y1, other.x2, other.y2)
    elseif other.shape_type == 'rectangle' or other.shape_type == 'polygon' then
      colliding = math.line_polygon(self.x1, self.y1, self.x2, self.y2, unpack(other.vertices))
    elseif other.shape_type == 'circle' then
      colliding = math.line_circle(self.x1, self.y1, self.x2, self.y2, other.x, other.y, other.rs)
    end
  elseif self.shape_type == 'rectangle' or self.shape_type == 'polygon' then
    if other.shape_type == 'point' then
      colliding = math.point_polygon(other.x, other.y, unpack(self.vertices))
    elseif other.shape_type == 'line' then
      colliding = math.line_polygon(other.x1, other.y1, other.x2, other.y2, unpack(self.vertices))
    elseif other.shape_type == 'rectangle' or other.shape_type == 'polygon' then
      colliding = math.polygon_polygon(self.vertices, other.vertices)
    elseif other.shape_type == 'circle' then
      colliding = math.circle_polygon(other.x, other.y, other.rs, unpack(self.vertices))
    end
  elseif self.shape_type == 'circle' then
    if other.shape_type == 'point' then
      colliding = math.point_circle(other.x, other.y, self.x, self.y, self.rs)
    elseif other.shape_type == 'line' then
      colliding = math.line_circle(other.x1, other.y1, other.x2, other.y2, self.x, self.y, self.rs)
    elseif other.shape_type == 'rectangle' or other.shape_type == 'polygon' then
      colliding = math.circle_polygon(self.x, self.y, self.rs, unpack(other.vertices))
    elseif other.shape_type == 'circle' then
      colliding = math.circle_circle(self.x, self.y, self.rs, other.x, other.y, other.rs)
    end
  end

  -- Generate .enter/.leave/.active for collisions with the other object and return it
  -- NOTE: one small problem is that .enter/.leave only become true if this function has been called once before for the same object
  -- So in some cases where a flag is set and :is_colliding_with is called in the same frame, .enter/.leave will be unable to return true in that frame if a collision is already happening
  -- This 1 frame delay may become relevant in some situation so I'm leaving this note here for the future
  -- TODO: figure out a way to get rid of this 1 frame delay while keeping the API similar
  if not self.collisions[other] then
    self.collisions[other] = {enter = false, leave = false, active = colliding}
  end
  self.collisions[other].enter = false
  self.collisions[other].leave = false
  if colliding and not self.previous_collisions[other] then
    self.collisions[other].enter = true
  elseif not colliding and self.previous_collisions[other] then
    self.collisions[other].leave = true
  end
  self.collisions[other].active = colliding
  self.previous_collisions[other] = colliding
  
  -- self.is_colliding_with_has_been_called_this_frame[other] = true
  return self.collisions[other]
end
