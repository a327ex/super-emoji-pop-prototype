transform = class:use()
function transform:transform(x, y, r, sx, sy, z)
  self.x, self.y, self.z = x or 0, y or 0, z
  self.r = r or 0
  self.sx, self.sy = sx or 1, sy or sx or 1
end

-- Moves the object by the given amount while multiplying by dt
-- self:move(10, 10) -> moves the object at 10 units per second on both axes
function transform:move(dx, dy)
  if type(dx) == 'table' then
    self.x = self.x + dx.x*game.rate
    self.y = self.y + dx.y*game.rate
  else
    self.x = self.x + dx*game.rate
    self.y = self.y + dy*game.rate
  end
end

-- Moves the object to the target location either using a given speed or a maximum time
-- max_time will override speed since it will make the object reach the target in the given time
-- If speed and max_time are omitted then the object will teleport to the target location
-- self:move_to(player.transform.x, player.transform.y, 40) -> moves towards the player at 40 speed
-- self:move_to(player.transform, nil, nil, 2) -> moves towards the player with speed such that it would reach him in 2 seconds if he never moved
function transform:move_to(tx, ty, speed, max_time)
  if type(tx) == 'table' then
    if not speed and not max_time then self.x, self.y = tx.x, tx.y; return end
    if max_time then speed = math.distance(self.x, self.y, tx.x, tx.y)/max_time end
    local r = math.angle_to(self.x, self.y, tx.x, tx.y)
    self:move(speed*math.cos(r), speed*math.sin(r))
  else
    if not speed and not max_time then self.x, self.y = tx, ty; return end
    if max_time then speed = math.distance(self.x, self.y, tx, ty)/max_time end
    local r = math.angle_to(self.x, self.y, tx, ty)
    self:move(speed*math.cos(r), speed*math.sin(r))
  end
end


function transform:move_along_angle(v, r)
  self.x = self.x + v*math.cos(r)*game.rate
  self.y = self.y + v*math.sin(r)*game.rate
end

-- Gets this object's screen transformition, returns its normal transformition if it is fixed
function transform:get_screen_transform()
  if self:is(fixed) then
    return self.x, self.y
  else
    return camera:get_local_coords(self.x, self.y)
  end
end

-- Rotates the object towards the target angle using rotational lerp, which is a value from 0 to 1
-- Higher values will rotate the object faster, lower values will make the turn have a smooth delay to it
-- If lerp_value is omitted then the will rotate immediately to the target angle
-- self:rotate_to(self.r + math.pi/4, 0.2) -> rotates the object 45 degrees to its left with lerp value 0.2
-- self:rotate_to(self.r + math.pi/4) -> rotates the object 45 degrees to its left immediately
function transform:rotate_to(r, lerp_value)
  if lerp_value then
    self.r = math.lerp_angle_dt(lerp_value, g.rate, self.r, r or 0)
  else
    self.r = r or 0
  end
end

-- Same as rotate_to, except to a target point instead of an angle
function transform:rotate_to_point(x, y, lerp_value)
  local target_r = math.angle_to(self.x, self.y, x, y)
  if lerp_value then
    self.r = math.lerp_angle_dt(lerp_value, g.rate, self.r, math.angle_to(self.x, self.y, x, y))
  else
    self.r = math.angle_to(self.x, self.y, x, y)
  end
end

function transform:scale_to(sx, sy)
  if type(sx) == 'table' then
    self.sx = sx.x
    self.sy = sx.y or sx.x or 1
  else
    self.sx = sx or 1
    self.sy = sy or sx or 1
  end
end
