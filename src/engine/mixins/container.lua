-- This is responsible for holding game objects and performing operations on them.
-- You should create one container object for each type of object that's relevant for your game according to access patterns.
-- If you always need to run checks on player and enemy game objects, then each should have its own container, or maybe they should share the same one if it makes sense.
-- Create a new container as a new object: "self.players = make(container())"
container = class:use()
function container:new(weak) self:container(weak) end
function container:container(weak)
  self.objects = {}
  self.by_id = {}
  self.by_name = {}
  self.by_tag = {}

  self.weak = weak
  if self.weak then
    setmetatable(self.objects, {__mode = 'v'})
    setmetatable(self.by_id, {__mode = 'v'})
    setmetatable(self.by_name, {__mode = 'v'})
  end
end
-- TODO: check if weak containers are working properly when objects are deleted, there's a leak somewhere and I think it's something to do with this

-- Runs the action for each game object in the container.
function container:for_each(action)
  for _, object in ipairs(self.objects) do
    action(object)
  end
end

-- Runs the action for each game object in the container, filtered by tag (a tag is just string).
function container:for_each_by_tag(tag, action)
  for _, object in ipairs(self.by_tag[tag]) do
    action(object)
  end
end

-- Adds a new object to the container.
-- players = container()
-- p = players:add(player{name = 'player_1', x = g.w/2, y = g.h/2, v = 200})
-- print(players.by_name.player_1.v, p.v) -> 200, 200
function container:add(object)
  object.container = self
  table.insert(self.objects, object)
  self.by_id[object.id] = object
  if object._name then self.by_name[object._name] = object end
  if object._tags then
    for tag, _ in pairs(object._tags) do
      if not self.by_tag[tag] then
        self.by_tag[tag] = {}
        if self.weak then setmetatable(self.by_tag[tag], {__mode = 'v'}) end
      end
      table.insert(self.by_tag[tag], object)
    end
  end
end

-- Runs the action for each game object in the container and removes the ones for which it returns true.
-- enemies = container()
-- enemies:remove(function(object) return object.x > 400 end) -> removes all objects where its x position is bigger than 400
local are_objects_equal = function(a, b) return a.id == b.id end
function container:remove(action)
  for i = #self.objects, 1, -1 do
    local object = self.objects[i]
    if action(object) then
      if object.destroy then object:destroy() end
      table.remove(self.objects, i)
      self.by_id[object.id] = nil
      if object._name then self.by_name[object._name] = nil end
      if object._tags then
        for tag, _ in pairs(object._tags) do
          table.delete(self.by_tag[tag], are_objects_equal, object)
        end
      end
    end
  end
end

-- Returns true if the container has no objects in it.
function container:empty()
  return #self.objects <= 0
end

-- Updates the object grid for this container.
-- This grid is used for fast retrieval of objects in a given area.
-- Cell size is the size of each cell in the grid.
-- Game objects should never have their bounding box bigger than a grid cell. An error will happen if this is violated.
-- enemies:update_grid(64)
function container:update_grid(cell_size)
  self.cell_size = cell_size or self.cell_size or 64
  self.grid = {}
  for _, object in ipairs(self.objects) do
    if object.w > self.cell_size or object.h > self.cell_size then error('Game object size > grid cell size.') end
    object.cells = {}
    local cx, cy = math.floor((object.x - object.w*0.5)/self.cell_size), math.floor((object.y - object.h*0.5)/self.cell_size)
    for i = cx-1, cx+1 do
      for j = cy-1, cy+1 do
        if not self.grid[i] then self.grid[i] = {} end
        if not self.grid[i][j] then self.grid[i][j] = {} end
        table.insert(self.grid[i][j], object)
        table.insert(object.cells, {i, j})
      end
    end
  end
end

-- Calculate offsets used to search for new cells when the previous one is not empty, outward anti-clockwise motion from center
local cell_offsets = {}
table.insert(cell_offsets, {0, 0})
for i = 1, 10 do -- change this value to suit your needs better, 10 means it will look at most 10 cells away from the center in all directions
  local p = {i, 0}
  for j = p[2], -i, -1 do p[2] = j; table.insert(cell_offsets, {p[1], p[2]}) end
  for j = p[1]-1, -i, -1 do p[1] = j; table.insert(cell_offsets, {p[1], p[2]}) end
  for j = p[2]+1, i do p[2] = j; table.insert(cell_offsets, {p[1], p[2]}) end
  for j = p[1]+1, i do p[1] = j; table.insert(cell_offsets, {p[1], p[2]}) end
  for j = p[2]-1, 1, -1 do p[2] = j; table.insert(cell_offsets, {p[1], p[2]}) end
end

-- Returns the center position of the first free cell around the passed position that has no objects in it.
-- enemies:get_free_nearby_cell_position(0, 0) -> returns the position of the first cell around 0, 0 that has no enemies in it
function container:get_free_nearby_cell_position(x, y)
  if not self.cell_size then return end -- needs to be initialized as a container with a grid, call self:update_grid at least once before calling this
  local x, y = math.floor(x/self.cell_size), math.floor(y/self.cell_size)
  local px, py = nil, nil
  for i = 1, #cell_offsets do
    local cx, cy = x + cell_offsets[i][1], y + cell_offsets[i][2]
    if not (self.grid[cx] and self.grid[cx][cy] and #self.grid[cx][cy] > 0) then
      px, py = cx*self.cell_size, cy*self.cell_size
      break
    end
  end
  return px, py
end

-- Returns all objects in the current grid cell as well as in all cells around the current one by "s" units.
-- enemies:get_objects_in_cells(0, 0, 20) -> returns all objects in the 0, 0 cell as well as math.floor(20/enemies.cell_size) cells in all directions from that one.
-- In this example, if enemies.cell_size is 16 then it will return objects in cells that are direct neighbors of the middle one.
-- "condition" is an optional function that receives an object and returns true if it should be included in the output table.
function container:get_objects_in_cells(x, y, s, condition)
  if not self.cell_size then error('cell size not set for container while trying to call "get_objects_in_cells"') end
  local objects = {}
  local x, y, s = math.floor(x/self.cell_size), math.floor(y/self.cell_size), math.floor(s/self.cell_size)
  for cx = x-s, x+s do
    for cy = y-s, y+s do
      if self.grid[cx] then
        for _, object in ipairs(self.grid[cx][cy] or {}) do
          if not condition or (condition and condition(object)) then
            table.insert(objects, object)
          end
        end
      end
    end
  end
  return objects
end

-- Returns all objects that are bounding box collisions (might not be full exact collisions) to the "source" object except itself.
-- This first gets all objects that in the same grid cells "source" is in, and then checks if the bounding boxes of each of those objects are possible collisions.
-- Full collision checks should be done elsewhere at the user's discretion since they're more expensive.
function container:get_bounding_box_collisions(source)
  local objects = {}
  for _, cell in ipairs(source.cells) do
    if self.grid[cell[1]] and self.grid[cell[1]][cell[2]] then
      for _, object in ipairs(self.grid[cell[1]][cell[2]]) do
        if object.id ~= source.id and object:is('area') and math.rectangle_rectangle(object.x, object.y, object.w, object.h, source.x, source.y, source.w, source.h) then
          table.insert(objects, object)
        end
      end
    end
  end
  return objects
end

-- Returns the closest object to the given point.
-- enemies:get_closest_object(player.x, player.y) -> gets the closest enemy to the player.
-- "condition" is an optional function that receives an object and returns true if it should be considered for the calculation.
-- TODO: 
--   optimize this by implementing get_occupied_nearby_cell_position which is the reverse of get_free_nearby_cell_position
--   this is an optimization because instead of checking against all objects, it will check per cell moving outwards from the center one
function container:get_closest_object(x, y, condition)
  local min_d, min_i = 1000000, 0
  for i, object in ipairs(self.objects) do
    local d = math.distance(x, y, object.x, object.y)
    if d < min_d and (not condition or (condition and condition(object))) then
      min_d = d
      min_i = i
    end
  end
  return self.objects[min_i]
end

-- Destroys all objects and resets the container.
function container:destroy()
  for _, object in ipairs(self.objects) do
    if object.destroy then
      object:destroy()
    end
  end
  self.objects = {}
  self.by_id = {}
  self.by_name = {}
  self.by_tag = {}
end
