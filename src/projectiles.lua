emoji_projectile = class:use(transform, hitfx, area)
function emoji_projectile:new(x, y, v, r, emoji_name)
  self:transform(x, y, 0, 22/images[emoji_name].w, 22/images[emoji_name].h)
  self:hitfx()
  self:area('rectangle', 24, 10)

  self.emoji_name = emoji_name
  self.emoji = images[self.emoji_name]
  self:hitfx_add('hit', 1)
  self:hitfx_use('hit', 0.5, nil, nil, 0.125)
  self.v = v or random:float(150, 200)
  self.r = r or random:angle()
end

function emoji_projectile:update(dt)
  self:move_along_angle(self.v, self.r)
  push('game_2', self.x, self.y, self.r + 5*math.pi/4, self.sx*self.springs.hit.x, self.sy*self.springs.hit.x)
    self.emoji:draw('game_2', self.x, self.y, 0, 1, 1, nil, nil, self.flashes.hit.x and colors.fg[0], self.flashes.hit.x and shaders.combine)
  pop('game_2')

  -- self:area_draw('game_2', colors.blue[0], 2)

  for _, enemy in ipairs(enemies:get_objects_in_cells(self.x, self.y, 2*self.w)) do
    local enemy_collision = enemy:is_colliding_with(self)
    if enemy_collision.enter then
      local r = math.angle_to(enemy.x, enemy.y, self.x, self.y)
      local x, y = enemy.x + enemy.rs*math.cos(r), enemy.y + enemy.rs*math.sin(r)
      enemy:hit(x, y, 1)
      self:hitfx_use('hit', 0.5, 250, 20, 0.125)
    end
  end
end


enemy_projectile = class:use(transform, timer, hitfx, area)
function enemy_projectile:new(x, y, v, r, color)
  self:transform(x, y)
  self:timer()
  self:hitfx()
  self:area('rectangle', 15, 7)

  self:hitfx_add('hit', 1)
  self:pull('hit', 0.5)
  self.v = v or random:float(150, 200)
  self.r = r or random:angle()
  self.color = colors.fg[0]
  self:after(0.2, function()
    self.color = color or colors.red[0]
    self.damping = true
  end)
end

function enemy_projectile:update(dt)
  self:move_along_angle(self.v, self.r)
  if self.damping then
    self.v = math.velocity_damping(self.v, nil, 0.0005, dt)
    if self.v <= 20 then
      self:hit()
    end
  end
  push('game_2', self.x, self.y, self.r, self.sx*self.springs.hit.x, self.sy*self.springs.hit.x)
    rectangle('game_2', self.x, self.y, self.w, self.h, self.w/4, self.h/2, self.color)
  pop('game_2')
end

function enemy_projectile:hit()
  self.dead = true
  effects:add(hit_circle(self.x, self.y, 12, 0.25, colors.white[0], self.color))
end
