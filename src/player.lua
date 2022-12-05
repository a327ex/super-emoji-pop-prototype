pointer = class:use(transform, area, timer, hitfx, stats, health)
function pointer:new(emoji)
  self:transform(game.w/2, game.h/2, 0, 24/images[emoji].w, 24/images[emoji].h)
  self:area('circle', 1)
  self:timer()
  self:hitfx()
  self:stats()
  self:health(3)
  self.collider = collider(self.x, self.y, 'circle', 10)
  players:add(self.collider)
  -- self.collider is used for collision with enemy hazards other than enemy emojis
  -- this is because collision with enemy emojis should be precise on the pointer's finger,
  -- while collision with enemy projectiles and other hazards should be focused on the rest of the hand instead

  self.attack = 1
  self.emoji_name = emoji
  self.emoji = images[emoji]
  self:hitfx_add('hit', 1)
  self:hitfx_add('attack', 1)
  self:set_stat('attack_rate', 1, 0.1, 10)
  self:cooldown(0.5, function() return true end, function() self.can_attack = true end, nil, nil, 'attack')

  self.passives = {}
end

function pointer:update(dt)
  self.x, self.y = camera:get_mouse_position()
  self.collider.x, self.collider.y = self.x + 8, self.y + 14
  if not self.hidden then self.emoji:draw('ui_2', self.x + 8, self.y + 12, -math.pi/8, self.sx*self.springs.attack.x, self.sy*self.springs.attack.x, nil, nil, nil, nil, nil, true) end
  self:set_multiplier('attack', self.stat.attack_rate.x)

  -- self:area_draw('screen', colors.blue[0], 2)
  -- self.collider:area_draw('screen', colors.blue[0], 2)

  for _, enemy in ipairs(enemies:get_objects_in_cells(self.x, self.y, self.rs)) do
    local enemy_collision = enemy:is_colliding_with(self)
    if enemy_collision.enter then -- or (enemy_collision.active and self.can_attack) then
      local r = math.angle_to(enemy.x, enemy.y, self.x, self.y)
      local x, y = enemy.x + enemy.rs*math.cos(r), enemy.y + enemy.rs*math.sin(r)
      enemy:hit(x, y, self.attack)
      self:pull('attack', 0.5, 250, 20)

      if self.passives.chili then
        if random:bool(50) then
          local nearby_enemies = enemies:get_objects_in_cells(enemy.x, enemy.y, 80, function(e) return e.id ~= enemy.id end)
          local nearby_enemy = random:table(nearby_enemies)
          if nearby_enemy then nearby_enemy:hit(nearby_enemy.x, nearby_enemy.y, 1) end
        end
      end
    end
  end

  for _, projectile in ipairs(projectiles:get_objects_in_cells(self.collider.x, self.collider.y, 2*self.collider.rs)) do
    if projectile:is(enemy_projectile) then
      local projectile_collision = projectile:is_colliding_with(self.collider)
      if projectile_collision.enter then
        self:hit()
        projectile:hit()
      end
    end
  end

  self.can_attack = false

  --[[
  if input.act.pressed then
    projectiles:add(enemy_projectile(self.x, self.y, random:float(150, 200), random:angle(), colors.red[0]))
  end
  ]]--
end

function pointer:hit()
  if self.invincible then return end
  self.invincible = true
  self:every(0.05, function() self.hidden = not self.hidden end, 2/0.05, function() self.hidden = false end, 'hit_hidden')
  self:after(2, function() self.invincible = false end, 'hit_invincible')
  self:hitfx_use('hit', 0.25, nil, nil, 0.25)
  camera:shake(4, 0.4)
  game:slow(0.5, 1)
  sounds[random:table{'player_hit1', 'player_hit2'}]:play(0.5, random:float(0.95, 1.05))
  if self.passives.melon and self.melon_active then
    self.melon_active = false
    sounds.melon:play(0.5, random:float(0.95, 1.05))
  else
    if self:hurt(1) then
      if self.passives.mushroom then
        self.hp = 1
        sounds.revive:play(0.5, random:float(0.95, 1.05))
      else
        self.dead = true
        sounds.player_death:play(0.5, random:float(0.95, 1.05))
      end
    end
  end
  health_ui:refresh()
end

function pointer:add_passive(passive_name)
  table.insert(self.passives, passive_name)
  self.passives[passive_name] = true

  if passive_name == 'dagger' then
  elseif passive_name == 'fire' then
  elseif passive_name == 'knife' then
    players:add(knife(self))
  elseif passive_name == 'chili' then
  elseif passive_name == 'melon' then
    self.melon_active = true
  elseif passive_name == 'chocolate' then
    self.max_hp = self.max_hp + 1
    self.attack = self.attack + 1
    self.hp = self.max_hp
  elseif passive_name == 'croissant' then
  elseif passive_name == 'hotdog' then
    self.max_hp = self.max_hp + 2
    self.hp = self.hp + 2
  elseif passive_name == 'bacon' then
    self.max_hp = self.max_hp + 1
    self.hp = self.hp + 1
  elseif passive_name == 'mushroom' then
  end
end


knife = class:use(transform, area, hitfx)
function knife:new(parent)
  self.emoji = images.knife
  self:transform(parent.collider.x + 32, parent.collider.y, 0, 24/self.emoji.w, 24/self.emoji.h)
  self:area('rectangle', 24, 10)
  self:hitfx()

  self.parent = parent
  self.orbit_r = 0
  self:hitfx_add('attack', 1)
end

function knife:update(dt)
  self.orbit_r = self.orbit_r - 0.35*math.pi*dt
  self.r = self.orbit_r
  self.x, self.y = self.parent.collider.x + 32*math.cos(self.orbit_r), self.parent.collider.y + 32*math.sin(self.orbit_r)
  self.emoji:draw('ui_2', self.x, self.y, self.r - math.pi/4, self.sx*self.springs.attack.x, self.sy*self.springs.attack.x, nil, nil, self.flashes.attack.x and colors.fg[0], self.flashes.attack.x and shaders.combine)

  -- self:area_draw('ui_2', colors.blue[0], 2)

  for _, enemy in ipairs(enemies:get_objects_in_cells(self.x, self.y, 2*self.w)) do
    local enemy_collision = enemy:is_colliding_with(self)
    if enemy_collision.enter then
      local r = math.angle_to(enemy.x, enemy.y, self.x, self.y)
      local x, y = enemy.x + enemy.rs*math.cos(r), enemy.y + enemy.rs*math.sin(r)
      enemy:hit(x, y, 1)
      self:hitfx_use('attack', 0.5, 250, 20, 0.125)
    end
  end
end
