timer_ui = class:use(transform)
function timer_ui:new(x, y)
  self:transform(x, y)
  self.emoji = images.smiling_imp
  self.sx, self.sy = 18/self.emoji.w, 18/self.emoji.h
end

function timer_ui:update(dt)
  self.minutes = string.format('%02d', tostring(math.floor(game.time/60)))
  self.seconds = string.format('%02d', tostring(math.round(game.time%60, 0)))
  self.emoji:draw('ui', self.x, self.y, 0, self.sx, self.sy)
  for i = 1, 2 do images['letter_' .. self.minutes:sub(i, i)]:draw('ui', self.x + 22 + (i-1)*12, self.y, 0, 10/72, 10/72) end
  for i = 1, 2 do images['letter_' .. self.seconds:sub(i, i)]:draw('ui', self.x + 48 + (i-1)*12, self.y, 0, 10/72, 10/72) end

  rectangle('ui', self.x + 28, self.y + 17, 74, 4, 2, 2, colors.black[0])
  rectangle('ui', self.x - 2, self.y + 17, 16, 4, 0, 0, colors.green[0])
  rectangle('ui', self.x + 14, self.y + 17, 16, 4, 0, 0, colors.yellow[0])
  rectangle('ui', self.x + 30, self.y + 17, 15, 4, 0, 0, colors.brown[0])
  rectangle('ui', self.x + 45, self.y + 17, 15, 4, 0, 0, colors.orange[0])
  rectangle('ui', self.x + 60, self.y + 17, 15, 4, 0, 0, colors.red[0])

  local n = math.remap(game.time, 0, 120, 0, 77)
  triangle_equilateral('ui', self.x - 10 + n, self.y + 24, 5, -math.pi/2, colors.fg[0])
  local text = ''
  if n >= 0 and n < 16 then text = 'easy' end
  if n >= 16 and n < 32 then text = 'normal' end
  if n >= 32 and n < 47 then text = 'hard' end
  if n >= 47 and n < 63 then text = 'very hard' end
  if n >= 63 then text = 'insane' end
  print_text('ui', text, fonts.lana, self.x - 20 + n, self.y + 25)
end


emoji_ui = class:use(transform, timer, hitfx, parent)
function emoji_ui:new(x, y, ui_type)
  self:transform(x, y)
  self:timer()
  self:hitfx()

  self.ui_type = ui_type
  if self.ui_type == 'attack' then
    self.emoji = images.swords
    self.value = player.attack
  elseif self.ui_type == 'health' then
    self.emoji = images.heart
    self.value = player.hp
  end
  self.w, self.h = 18, 18
  self.sx, self.sy = self.w/self.emoji.w, self.h/self.emoji.h
  self.oy = {0, 0}
  self.characters = {}
  self:hitfx_add('hit_1', 1)
  self:hitfx_add('hit_2', 1)
  self:refresh()
end

function emoji_ui:update(dt)
  self.emoji:draw('ui', self.x, self.y + self.oy[1], 0, self.sx*self.springs.hit_1.x, self.sy*self.springs.hit_2.x)
  push('ui', self.x + 18 + 4 + #self.characters*6, self.y + 1 + self.oy[2], 0, self.springs.hit_2.x, self.springs.hit_2.x)
    for i, t in ipairs(self.characters) do
      t:draw('ui', self.x + 18 + 4 + (i-1)*12, self.y + 1 + self.oy[2], 0, 10/72, 10/72)
    end
  pop('ui')
end

function emoji_ui:refresh()
  if self.ui_type == 'attack' then self.value = player.attack
  elseif self.ui_type == 'health' then self.value = player.hp end
  local value = tostring(self.value)
  self.characters = {}
  for i = 1, #value do table.insert(self.characters, images['letter_' .. value:sub(i, i)]) end
  for i = 1, 2 do
    self:after((i-1)*0.03, function()
      self.oy[i] = 3
      self:tween(0.2, self.oy, {[i] = 0}, math.linear, nil, 'oy' .. i)
    end)
  end
  self:pull('hit_1', 0.2)
  self:pull('hit_1', 0.1)
end


passive_box = class:use(transform, timer, hitfx, area)
function passive_box:new(x, y, emoji)
  self:transform(x, y, 0, 24/images[emoji].w, 24/images[emoji].h)
  self:timer()
  self:hitfx()

  self.emoji_name = emoji
  self.emoji = images[emoji]
  self.title = text('[' .. emoji .. '](wavy3)', {font = fonts.fat})
  self.description = text(item_to_description[emoji], {font = fonts.lana})
  self:hitfx_add('hover', 1)

  if (self.title.w + 2*34) >= self.description.w then self.w, self.h = self.title.w + 100, self.title.h + self.description.h + 12
  else self.w, self.h = self.description.w + 50, self.title.h + self.description.h + 12 end
  self:area('rectangle', self.w, self.h)

  self.bg_sx, self.bg_sy = 0, 0
end

function passive_box:update(dt)
  local player_collision = self:is_colliding_with(player)
  if player_collision.enter then
    self.hot = true
    self:tween(0.15, self, {bg_sx = 1, bg_sy = 1}, math.cubic_in_out, nil, 'bg_sy')
    self:pull('hover', 0.15)
    sounds.ui_hover:play(0.5, random:float(0.95, 1.05))
  end

  if player_collision.leave then
    self.hot = false
    self:tween(0.15, self, {bg_sx = 0, bg_sy = 0}, math.cubic_in_out, nil, 'bg_sy')
  end

  if self.hot and input.act.pressed then
    sounds.ui_click1:play(0.5, random:float(0.95, 1.05))
    sounds.ui_click2:play(0.5, random:float(0.95, 1.05))
    self:hitfx_use('hover', 0.5, nil, nil, 0.15)
    player:add_passive(self.emoji_name)
    self:after(0.15, function()
      level = level + 1
      passive_box_1.dead = true
      passive_box_2.dead = true
      passive_box_3.dead = true
      passive_box_1 = nil
      passive_box_2 = nil
      passive_box_3 = nil
      game:go('arena')
    end)
  end

  push('ui', self.x, self.y, 0, self.springs.hover.x, self.springs.hover.x)
    if self.hot then
      rectangle('ui_bg', self.x, self.y, game.w + 40, self.h*self.bg_sy, 0, 0, self.flashes.hover.x and colors.white[0] or colors.yellow[0])
      texture('ui_bg', function() gfx.rectangle(self.x, self.y, (game.w + 40)*self.springs.hover.x, self.springs.hover.x*self.h*self.bg_sy, 0, 0, colors.fg[0]) end, function()
        local w, h = self.w*0.5, 0.5*self.h*self.bg_sy
        gfx.push(self.x, self.y, 0, self.bg_sx)
          gfx.polygon({self.x - w - 25, self.y - h, self.x + w, self.y - h, self.x + w + 25, self.y + h, self.x - w, self.y + h}, self.flashes.hover.x and colors.white[-1] or colors.yellow[-3])
        gfx.pop()
      end)
    end
    self.emoji:draw('ui', self.x - self.title.w/2 - 20, self.y - 10 + 1.25*math.sin(4*game.time), 0, self.sx, self.sy)
    self.emoji:draw('ui', self.x + self.title.w/2 + 18, self.y - 10 + 1.25*math.sin(4*game.time + #self.title.characters), 0, -self.sx, self.sy)
    self.title:update('ui', dt, self.x, self.y - 4)
    self.description:update('ui', dt, self.x, self.y + 14)
  pop('ui')
end


hp_bar = class:use(transform, parent, timer)
function hp_bar:new(enemy, oy)
  self:transform(0, oy)
  self:parent_init(enemy, true)
  self:timer()
  self:after(1, function() self.dead = true end)
end

function hp_bar:update(dt)
  if self:parent_update(dt) then return end
  rectangle('ui', self.parent.x + self.x, self.parent.y + self.y, self.parent.w*self.parent.springs.hover.x, 4*self.parent.springs.hover.x, 2, 2, colors.black[0])
  rectanglel('ui', self.parent.x + self.x - self.parent.w*0.5*self.parent.springs.hover.x, self.parent.y + self.y - 2*self.parent.springs.hover.x,
    (self.parent.hp/self.parent.max_hp)*self.parent.w*self.parent.springs.hover.x, 4*self.parent.springs.hover.x, 2, 2, colors.red[0])
end


emoji_text = class:use(transform, timer)
function emoji_text:new(x, y, text, duration_mult)
  self:transform(x - 4, y, 0, 14/72, 14/72)
  self:timer()

  self.characters = {}
  for i = 1, #text do
    local c = utf8.sub(text, i, i)
    if c == '+' then
      local character = {emoji = images.plus.image, r = random:float(-math.pi/16, math.pi/16), vr = random:float(-math.pi/4, math.pi/4), oy = 0}
      table.insert(self.characters, character)
    else
      local character = {emoji = images['letter_' .. c].image, r = random:float(-math.pi/16, math.pi/16), vr = random:float(-math.pi/4, math.pi/4), oy = 0}
      table.insert(self.characters, character)
    end
  end
  self.vy = -24
  self:after(0.5*(duration_mult or 1), function() self:tween(1*(duration_mult or 1), self, {sx = 0, sy = 0}, math.linear, function() self.dead = true end) end)
end

function emoji_text:update(dt)
  for i, c in ipairs(self.characters) do
    c.r = c.r + c.vr*dt
    c.oy = 4*math.sin(game.time + i)
  end
  self.y = self.y + self.vy*dt
  local w, h = #self.characters*12, 10
  local x, y = self.x - w/2, self.y
  for i, c in ipairs(self.characters) do
    draw('ui', c.emoji, x + (i-1)*12 + 5, y + c.oy, c.r, self.sx, self.sy)
  end
end
