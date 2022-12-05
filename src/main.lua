require 'engine'
start({
  w = 640, h = 360,
  name = 'super emoji pop',
  theme = 'twitter_emoji',
})

require 'decorations'
require 'effects'
require 'enemies'
require 'player'
require 'projectiles'
require 'ui'

function init()
  layers(
    {'default'},
    {'bg'},
    {'shadow', x = 4*game.sx, y = 4*game.sy, shadow = true, layers = {'game', 'effects'}},
    {'game', outline = 2},
    {'game_2', outline = 2},
    {'effects', outline = 2},
    {'ui_bg'},
    {'ui', outline = 2},
    {'ui_2', outline = 2},
    {'screen'}
  )

  input:bind('left', {'key:left', 'key:a', 'axis:leftx-', 'button:dpleft'})
  input:bind('right', {'key:right', 'key:d', 'axis:leftx+', 'button:dpright'})
  input:bind('up', {'key:up', 'key:w', 'axis:lefty-', 'button:dpup'})
  input:bind('down', {'key:down', 'key:s', 'axis:lefty+', 'button:dpdown'})
  input:bind('act', {'key:enter', 'key:space', 'mouse:1', 'button:fleft', 'button:fdown'})
  love.mouse.setVisible(false)

  frames = {}
  frames.hit1 = animation_frames(images.hit1, 96, 48)

  game:state('default', {'arena', 'default'})

  enemy_emojis = {'slight_smile', 'rage', 'clown', 'cloud'}
  player_emojis = {'index', 'metal', 'dagger', 'candle'}
  items = {'dagger', 'fire', 'knife', 'chili', 'melon', 'chocolate', 'croissant', 'hotdog', 'bacon', 'mushroom'}

  enemy_to_color = {
    ['slight_smile'] = 'yellow',
    ['rage'] = 'red',
    ['clown'] = 'brown',
    ['smiling_imp'] = 'purple',
    ['cloud'] = 'fg',
  }

  enemy_to_health = {
    ['slight_smile'] = 4,
    ['clown'] = 5,
    ['rage'] = 7,
    ['cloud'] = 14,
  }

  item_to_description = {
    ['dagger'] = '[50%](yellow) chance to launch a piercing dagger on kill, dealing [1](yellow) damage on hit',
    ['fire'] = '[35%](yellow) chance to burn enemies on hit, dealing [3](yellow) damage over 3 seconds',
    ['knife'] = '[orbits](yellow) around the pointer, dealing [1](yellow) damage on hit',
    ['chili'] = '[50%](yellow) chance to deal [1](yellow) damage to a nearby enemy on hit',
    ['melon'] = 'prevents damage taken [once](yellow) per round',
    ['chocolate'] = '[+1](yellow) damage and max health and [full heals](yellow)',
    ['croissant'] = '[+1](yellow) damage per round',
    ['hotdog'] = '[+2](yellow) max health',
    ['bacon'] = '[+1](yellow) max health',
    ['mushroom'] = 'revive with [1](yellow) health on death',
  }

  level_to_enemy_types = {
    [1] = {'slight_smile'},
    [2] = {'slight_smile', 'clown'},
    [3] = {'slight_smile', 'rage', 'clown'},
    [4] = {'slight_smile', 'cloud'},
    [5] = {'clown', 'rage', 'cloud'},
  }

  level_to_enemy_weights = {
    [1] = {1},
    [2] = {7, 3},
    [3] = {5, 3, 2},
    [4] = {7, 3},
    [5] = {2, 2, 6},
  }

  level_to_arena_size = {
    [1] = {0.15*game.w, 0.15*game.h},
    [2] = {0.20*game.w, 0.20*game.h},
    [3] = {0.25*game.w, 0.25*game.h},
    [4] = {0.30*game.w, 0.30*game.h},
    [5] = {0.35*game.w, 0.35*game.h},
  }
end

function update(dt)
  if game.states.default.enter then
    bg = background(game.w/2, game.h/2)
    players = container()
    enemies = container()
    effects = container()
    projectiles = container()
    ui = container()

    player = pointer('index')
    players:add(player)
    health_ui = emoji_ui(16, 16, 'health')
    attack_ui = emoji_ui(16, 42, 'attack')
    ui:add(health_ui)
    ui:add(attack_ui)
    ui:add(timer_ui(game.w - 72, 16))

    level = 1
    game:go('arena')
  end

  if game.states.arena.enter then
    arena_cleared = false
    arena_started = false
    local points = math.generate_poisson_disc_sampled_points(30, game.w/2, game.h/2, unpack(level_to_arena_size[level]))
    for i, point in ipairs(points) do
      game:after((i-1)*0.1, function()
        local enemy_type = random:weighted_pick(unpack(level_to_enemy_weights[level]))
        effects:add(spawn_effect(point.x, point.y, 14, nil, enemy_to_color[enemy_type], function()
          sounds.spawn:play(0.5, random:float(0.95, 1.05))
          enemies:add(enemy(point.x, point.y, level_to_enemy_types[level][enemy_type]))
        end))
      end)
    end
    game:after(#points*0.1 + 0.2, function()
      arena_started = true
      if player.passives.croissant then player.attack = player.attack + 1 end
      if player.passives.melon then player.melon_active = true end
      health_ui:refresh()
      attack_ui:refresh()
    end)
  end

  if game.states.arena.active then
    bg:update(dt)
    enemies:update_grid(32)
    projectiles:update_grid(32)

    players:for_each(function(self) self:update(dt) end)
    enemies:for_each(function(self) self:update(dt) end)
    projectiles:for_each(function(self) self:update(dt) end)
    effects:for_each(function(self) self:update(dt) end)
    ui:for_each(function(self) self:update(dt) end)

    enemies:remove(function(self) return self.dead end)
    projectiles:remove(function(self) return self.dead end)
    effects:remove(function(self) return self.dead end)
    ui:remove(function(self) return self.dead end)

    if enemies:empty() and arena_started and not arena_cleared then
      arena_cleared = true
      game:after(0.5, function()
        passive_box_1 = passive_box(game.w/2, game.h/2 - 80, random:table(items))
        passive_box_2 = passive_box(game.w/2, game.h/2, random:table(items))
        passive_box_3 = passive_box(game.w/2, game.h/2 + 80, random:table(items))
        ui:add(passive_box_1)
        ui:add(passive_box_2)
        ui:add(passive_box_3)
      end)
    end
  end
end
