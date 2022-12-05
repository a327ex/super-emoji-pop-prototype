spawn_effect = class:use(transform, timer, hitfx)
function spawn_effect:new(x, y, rs, color_1, color_2, action)
  self:transform(x, y)
  self:timer()
  self:hitfx()

  self.rs = 0
  self.color = color_1 or colors.fg[0]
  self:hitfx_add('main', 1)
  self:tween(0.1, self, {rs = rs or 6}, math.cubic_in_out, function()
    if action then action(x, y) end
    self:pull('main', 1)
    for i = 1, random:int(6, 8) do effects:add(hit_particle(self.x, self.y, random:float(150, 200), random:float(0.3, 0.5), self.color, color_2)) end
    self:tween(0.25, self, {rs = 0}, math.linear, function() self.dead = true end)
    if color_2 then self:after(0.15, function() self.color = color_2 end) end
  end)
end

function spawn_effect:update(dt)
  circle('effects', self.x, self.y, random:float(0.9, 1.1)*self.rs*self.springs.main.x, self.color)
end


hit_effect = class:use(transform)
function hit_effect:new(x, y)
  self:transform(x, y, random:angle())
  self.animation = animation(0.02, frames.hit1, 'once', {[0] = function() self.dead = true end})
end

function hit_effect:update(dt)
  self.animation:update('effects', dt, self.x, self.y, self.r, 1.35, 1.35)
end


fire_particle = class:use(transform, timer)
function fire_particle:new(x, y, v, r)
  self:transform(x, y, r)
  self:timer()

  self.rs = random:float(6.25, 7.5)*0.75
  self.r = r or random:angle()
  self.v = vec2(v*math.cos(self.r), v*math.sin(self.r))
  local r1, r2 = random:float(0.25, 0.0625), random:float(0.125, 0.375)
  self:after(r1, function() self:tween(r2, self, {rs = 0}, math.linear, function() self.dead = true end) end)
  self.color = colors.yellow[0]:clone()
  self.target_color = colors.red[0]
  self:tween(r1+r2, self.color, {r = self.target_color.r, g = self.target_color.g, b = self.target_color.b}, math.linear)
end

function fire_particle:update(dt)
  self.x, self.y = self.x + self.v.x*dt, self.y + self.v.y*dt
  self.v.x = math.velocity_damping(self.v.x, nil, 0.05, dt)
  self.v.y = self.v.y - 200*dt
  circle('effects', self.x, self.y, self.rs, self.color)
end


hit_particle = class:use(transform, timer)
function hit_particle:new(x, y, v, duration, color_1, color_2)
  self:transform(x, y, random:angle())
  self:timer()

  self.v = v
  self.duration = duration or 0.3
  self.w = math.remap(v, 0, 250, 0, 14)
  self.h = math.remap(v, 0, 250, 0, 7)
  self:tween(self.duration, self, {sx = 0, sy = 0, v = 0}, math.linear, function() self.dead = true end)
  self.color = color_1 or colors.fg[0]
  if color_2 then self:after(self.duration/2, function() self.color = color_2 end) end
end

function hit_particle:update(dt)
  self:move_along_angle(self.v, self.r)
  push('effects', self.x, self.y, self.r, self.sx, self.sy)
    rectangle('effects', self.x, self.y, self.w, self.h, self.w/4, self.h/2, self.color)
  pop('effects')
end


hit_circle = class:use(transform, timer)
function hit_circle:new(x, y, rs, duration, color_1, color_2)
  self:transform(x, y)
  self:timer()

  self.rs = rs or 12
  self.duration = duration or 0.2
  self:tween(self.duration, self, {sx = 0, sy = 0}, math.cubic_in_out, function() self.dead = true end)
  self.color = color_1 or colors.fg[0]
  if color_2 then self:after(self.duration/2, function() self.color = color_2 end) end
end

function hit_circle:update(dt)
  circle('effects', self.x, self.y, self.rs*self.sx, self.color)
end
