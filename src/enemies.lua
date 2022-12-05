enemy = class:use(transform, area, timer, hitfx, health)
function enemy:new(x, y, emoji_name, args)
  self:transform(x, y, 0, 22/images[emoji_name].w, 22/images[emoji_name].h)
  self:area('circle', 11)
  self:timer()
  self:hitfx()
  self:health(enemy_to_health[emoji_name])
  
  self.emoji_name = emoji_name
  self.emoji = images[emoji_name]
  self.w, self.h = self.emoji.w*self.sx, self.emoji.h*self.sy
  self:hitfx_add('hover', 1)
  self:hitfx_add('shoot', 1)
  self:hitfx_use('hover', 0.5, nil, nil, 0.15)

  self.teleports = 0
  self.shoot_color = colors.black[0]:clone()
  self.shoot_sx, self.shoot_sy = 1, 1

  if self.emoji_name == 'rage' then
    self:every({2, 8}, function() self:shoot() end, nil, nil, 'passive_shoot')

  elseif self.emoji_name == 'cloud' then
    args = args or {}
    self.split = args.split
    self.split_twice = args.split_twice
    if not self.split and not self.split_twice then
      self.sx, self.sy = 26/images[self.emoji_name].w, 26/images[self.emoji_name].h
    elseif self.split then
      self.sx, self.sy = 22/images[self.emoji_name].w, 22/images[self.emoji_name].h
      self:health(7)
    elseif self.split_twice then
      self.sx, self.sy = 18/images[self.emoji_name].w, 18/images[self.emoji_name].h
      self:health(3)
    end
  end
end

function enemy:update(dt)
  self.emoji:draw('game', self.x, self.y, self.r,
    (self.sx or 1)*self.springs.hover.x*self.springs.shoot.x*self.shoot_sx + (self.flashes.shoot.x and random:float(0, 0.05) or 0),
    (self.sy or 1)*self.springs.hover.x*self.springs.shoot.x*self.shoot_sy + (self.flashes.shoot.x and random:float(0, 0.05) or 0), nil, nil, 
    (self.flashes.hover.x and colors.fg[0]) or (self.flashes.shoot.x and self.shoot_color), (self.flashes.hover.x or self.flashes.shoot.x) and shaders.combine)
end

function enemy:hit(x, y, damage)
  self:hitfx_use('hover', 0.5, nil, nil, 0.125)
  ui:add(emoji_text(self.x, y - 16, tostring(damage), 0.35))
  if self:hurt(damage) then
    self:die(x, y)
  else
    effects:add(hit_effect(x, y))
    for i = 1, random:int(2, 4) do effects:add(hit_particle(x, y, random:float(75, 250), nil, nil, colors[enemy_to_color[self.emoji_name]][0])) end
    ui:add(hp_bar(self, self.w/2 + 6))
    sounds.enemy_hit:play(0.35, random:float(0.95, 1.05))

    if player.passives.fire then
      if random:bool(35) then
        self.burning = true
        self:every(0.05, function()
          effects:add(fire_particle(self.x, self.y + 10, random:float(0, 75), random:float(-math.pi - math.pi/6, math.pi/6)))
        end, nil, nil, 'fire_particles')
        self:every(1, function()
          self:hit(self.x, self.y, 1)
        end, 3, function()
          self.burning = false
          self:cancel('fire_particles')
        end, 'burning')
      end
    end

    if self.emoji_name == 'clown' then
      local runs = 0
      while not self:teleport(random:angle(), random:float(40, 80), 30) and runs < 100 do runs = runs + 1 end

    elseif self.emoji_name == 'rage' then
      self:shoot(0.3)
      self:every({2, 8}, function() self:shoot() end, nil, nil, 'passive_shoot')

    elseif self.emoji_name == 'cloud' then
      if not self.split and not self.split_twice then
        if self.hp <= math.floor(self.max_hp/2) then
          self:die(x, y)
          local r = random:angle()
          for i = 1, 2 do
            local cx, cy = self.x + 24*math.cos(r + (i-1)*math.pi), self.y + 24*math.sin(r + (i-1)*math.pi)
            cx, cy = enemies:get_free_nearby_cell_position(cx, cy)
            if cx >= 0 and cx <= game.w and cy >= 0 and cy <= game.h then 
              enemies:add(enemy(cx, cy, 'cloud', {split = true}))
              enemies:update_grid(32)
            end
          end
          sounds.cloud_spawn:play(0.35, random:float(0.95, 1.05))
        end
      elseif self.split then
        if self.hp <= math.floor(self.max_hp/2) then
          self:die(x, y)
          local r = random:angle()
          for i = 1, 4 do
            local cx, cy = self.x + 36*math.cos(r + (i-1)*math.pi/2), self.y + 36*math.sin(r + (i-1)*math.pi/2)
            cx, cy = enemies:get_free_nearby_cell_position(cx, cy)
            if cx >= 0 and cx <= game.w and cy >= 0 and cy <= game.h then 
              enemies:add(enemy(cx, cy, 'cloud', {split_twice = true}))
              enemies:update_grid(32)
            end
          end
          sounds.cloud_spawn:play(0.35, random:float(0.95, 1.05))
          sounds.cloud_spawn:play(0.35, random:float(0.95, 1.05))
        end
      end
    end
  end
end

function enemy:die(x, y)
  self.dead = true
  sounds[random:table{'enemy_die1', 'enemy_die2'}]:play(0.5, random:float(0.95, 1.05))
  effects:add(hit_circle(x or self.x, y or self.y, 18, 0.25, colors.white[0], colors[enemy_to_color[self.emoji_name]][0]))
  for i = 1, 4 do effects:add(hit_particle(x or self.x, y or self.y, random:float(100, 300), nil, nil, colors[enemy_to_color[self.emoji_name]][0])) end

  if player.passives.dagger then
    if random:bool(50) then
      local r = random:angle()
      local x, y = self.x + 24*math.cos(r), self.y + 24*math.sin(r)
      effects:add(hit_circle(x, y, 18, 0.25))
      for i = 1, random:int(4, 6) do effects:add(hit_particle(x, y, random:float(150, 300), random:float(0.3, 0.5))) end
      projectiles:add(emoji_projectile(x, y, random:float(250, 300), r, 'dagger'))
      sounds.dagger:play(0.5, random:float(0.95, 1.05))
    end
  end
end

-- Returns true if the teleport is successful.
-- A successful teleport is one where the new position is more than "rs" units from all other enemies.
function enemy:teleport(r, d, rs)
  local x, y = self.x + d*math.cos(r), self.y + d*math.sin(r)
  if x < 0 or x > game.w or y < 0 or y > game.h then return false end
  local closest = enemies:get_closest_object(x, y)
  if math.distance(x, y, closest.x, closest.y) >= rs then
    sounds.teleport:play(0.5, self.teleports*0.1 + 1)
    self.x, self.y = x, y
    self.teleports = self.teleports + 1
    return true
  end
end

function enemy:shoot(duration_mult)
  self:hitfx_use('shoot', 0.1, nil, nil, 2*(duration_mult or 1))
  self.shoot_color = colors.black[0]:clone()
  self:tween(2*(duration_mult or 1), self, {shoot_sx = 1.3, shoot_sy = 1.3}, math.linear)
  self:tween(2*(duration_mult or 1), self.shoot_color, {r = 1, g = 1, b = 1}, math.linear, function()
    self:tween(0.1, self, {shoot_sx = 1, shoot_sy = 1}, math.cubic_in_out, function() self.shoot_sx, self.shoot_sy = 1, 1 end)
    self:hitfx_use('hover', 0.5, nil, nil, 0.125)
    effects:add(hit_circle(self.x, self.y, 18, 0.25, colors.white[0], colors[enemy_to_color[self.emoji_name]][0]))
    for i = 1, random:int(4, 6) do effects:add(hit_particle(self.x, self.y, random:float(150, 300), random:float(0.3, 0.5), nil, colors[enemy_to_color[self.emoji_name]][0])) end
    local r = 0
    for i = 1, 4 do
      projectiles:add(enemy_projectile(self.x, self.y, random:float(250, 300), r + random:float(-math.pi/4, math.pi/4), colors.red[0]))
      r = r + math.pi/2
    end
    sounds.enemy_shoot:play(0.25, random:float(0.95, 1.05))
  end, 'shoot_flash')
end
