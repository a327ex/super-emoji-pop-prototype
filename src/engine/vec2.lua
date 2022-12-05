local EPSILON = 1e-6
local EPSILON_SQUARED = EPSILON*EPSILON
vec2 = class:use()
function vec2:new(x, y)
  self.x, self.y = x or 0, y or 0
end

function vec2:clone()
  return vec2(self.x, self.y)
end

function vec2:unpack()
  return self.x, self.y
end

function vec2:__tostring()
  return ("(%.2f, %.2f)"):format(self.x, self.y)
end

function vec2.equals(a, b)
  return math.abs(a.x - b.x) <= EPSILON and math.abs(a.y - b.y) <= EPSILON
end

function vec2.nequals(a, b)
  return math.abs(a.x - b.x) > EPSILON or math.abs(a.y - b.y) > EPSILON
end

function vec2:set(x, y)
  if not y then
    self.x = x.x
    self.y = x.y
  else
    self.x = x
    self.y = y
  end
  return self
end

function vec2:add(x, y)
  if not y then
    self.x = self.x + x.x
    self.y = self.y + x.y
  else
    self.x = self.x + x
    self.y = self.y + y
  end
  return self
end

function vec2:sub(x, y)
  if not y then
    self.x = self.x - x.x
    self.y = self.y - x.y
  else
    self.x = self.x - x
    self.y = self.y - y
  end
  return self
end

function vec2:mul(s)
  if type(s) == "table" then
    self.x = self.x*s.x
    self.y = self.y*s.y
  else
    self.x = self.x*s
    self.y = self.y*s
  end
  return self
end

function vec2:div(s)
  if type(s) == "table" then
    self.x = self.x*s.x
    self.y = self.y*s.y
  else
    self.x = self.x/s
    self.y = self.y/s
  end
  return self
end

function vec2:scale(k)
  self.x = self.x*k
  self.y = self.y*k
  return self
end

function vec2:rotate(r)
  local cos = math.cos(r)
  local sin = math.sin(r)
  local ox = self.x
  local oy = self.y
  self.x = cos*ox - sin*oy
  self.y = sin*ox + cos*oy
  return self
end

function vec2:rotate_around(r, p)
  self:sub(p)
  self:rotate(r)
  self:add(p)
  return self
end

function vec2:floor()
  self.x = math.floor(self.x)
  self.y = math.floor(self.y)
  return self
end

function vec2:ceil()
  self.x = math.ceil(self.x)
  self.y = math.ceil(self.y)
  return self
end

function vec2:round(p)
  self.x = math.round(self.x, p)
  self.y = math.round(self.y, p)
  return self
end

function vec2:dot(v)
  return self.x*v.x + self.y*v.y
end

function vec2:is_perpendicular(v)
  return math.abs(self:dot(v)) < EPSILON_SQUARED
end

function vec2:cross(v)
  return self.x*v.y - self.y*v.x
end

function vec2:is_parallel(v)
  return math.abs(self:cross(v)) < EPSILON_SQUARED
end

function vec2:is_zero()
  return math.abs(self.x) < EPSILON and math.abs(self.y) < EPSILON
end

function vec2:zero()
  self.x = 0
  self.y = 0
  return self
end

function vec2:length()
  return math.sqrt(self.x*self.x + self.y*self.y)
end

function vec2:length_squared()
  return self.x*self.x + self.y*self.y
end

function vec2:normalize()
  if self:is_zero() then return self end
  return self:scale(1/self:length())
end

function vec2:invert()
  self.x = self.x*-1
  self.y = self.y*-1
  return self
end

function vec2:limit(max)
  local s = max*max/vec2.length_squared(self)
  s = (s > 1 and 1) or math.sqrt(s)
  self.x = self.x*s
  self.y = self.y*s
  return self
end

function vec2:angle_to(v)
  return math.atan2(v.y - self.y, v.x - self.x)
end

function vec2:angle_difference(v)
  return math.angle_difference(self:angle(), v:angle())
end

function vec2:angle()
  return math.atan2(self.y, self.x)
end

function vec2:distance_squared(v)
  local dx = v.x - self.x
  local dy = v.y - self.y
  return dx*dx + dy*dy
end

function vec2:distance(v)
  return math.sqrt(self:distance_squared(v))
end

function vec2:bounce(normal, bounce_coefficient)
  local d = (1 + (bounce_coefficient or 1))*vec2.dot(normal)
  self.x = self.x - d*normal.x
  self.y = self.y - d*normal.y
  return self
end
