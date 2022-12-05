require 'engine/external/manual_gc'
require 'engine/external/measure'
mlib = require 'engine/external/mlib'
require 'engine/external/sort'
utf8 = require 'engine/external/utf8'

require 'engine/class'
require 'engine/system'
require 'engine/string'
for _, file in ipairs(system.enumerate_files('engine/mixins', '.lua')) do require('engine/mixins/' .. file) end
for _, file in ipairs(system.enumerate_files('engine', '.lua')) do if file ~= 'init' then require('engine/' .. file) end end

function start(args)
  -- All drawing is first sent to this table during the "update" function and then drawn afterwards.
  -- This means that from the user's perspective there's no need to have a separate draw function.
  -- There's also no need to worry about the order in which draw operations are called, since they will be automatically sorted later using the "layer" and "z" attributes.
  draw_commands = {}

  -- Objects that have these mixins are added to a weak container so that some of their functions (generally update or post_update) are called automatically.
  area_objects = {}
  state_objects = {}
  stats_objects = {}
  timer_objects = {}
  hitfx_objects = {}

  random = rng()
  game = screen(args)
  colors = game.colors
  love.joystick.loadGamepadMappings('engine/external/gamecontrollerdb.txt')
  input = action_input()
  input:bind_all_keyboard_keys()
  main_canvas = love.graphics.newCanvas(game.w, game.h, {msaa = game.smooth and 8 or 0})
  camera = camera2d(game.w/2, game.h/2)

  load_sounds()
  load_images()
  load_shaders()
  load_fonts()

  text_tags = {
    white = function(layer, dt, text, c, z, fixed) set_color(layer, colors.white[0], z, fixed) end,
    black = function(layer, dt, text, c, z, fixed) set_color(layer, colors.black[0], z, fixed) end,
    gray = function(layer, dt, text, c, z, fixed) set_color(layer, colors.gray[0], z, fixed) end,
    bg = function(layer, dt, text, c, z, fixed) set_color(layer, colors.bg[0], z, fixed) end,
    fg = function(layer, dt, text, c, z, fixed) set_color(layer, colors.fg[0], z, fixed) end,
    yellow = function(layer, dt, text, c, z, fixed) set_color(layer, colors.yellow[0], z, fixed) end,
    orange = function(layer, dt, text, c, z, fixed) set_color(layer, colors.orange[0], z, fixed) end,
    blue = function(layer, dt, text, c, z, fixed) set_color(layer, colors.blue[0], z, fixed) end,
    green = function(layer, dt, text, c, z, fixed) set_color(layer, colors.green[0], z, fixed) end,
    red = function(layer, dt, text, c, z, fixed) set_color(layer, colors.red[0], z, fixed) end,
    purple = function(layer, dt, text, c, z, fixed) set_color(layer, colors.purple[0], z, fixed) end,
    brown = function(layer, dt, text, c, z, fixed) set_color(layer, colors.brown[0], z, fixed) end,

    wavy1 = function(layer, dt, text, c, z, fixed) c.oy = 0.25*math.sin(2*game.time + c.i) end,
    wavy2 = function(layer, dt, text, c, z, fixed) c.oy = 0.5*math.sin(3*game.time + c.i) end,
    wavy3 = function(layer, dt, text, c, z, fixed) c.oy = 0.75*math.sin(3*game.time + c.i) end,
    wavy4 = function(layer, dt, text, c, z, fixed) c.oy = 2*math.sin(4*game.time + c.i) end,
  }

  game:go('default')
  layers({'default'})
end

function love.run()
  love.timer.step()

  local last_frame = 0
  local z_sort = function(a, b) return a.z < b.z end
  local draw_canvas = function(canvas, x, y, r, sx, sy, color, shader, flat)
    local color = color or colors.white[0]
    if shader then love.graphics.setShader(shader.shader) end
    if flat then
      love.graphics.setColor(color.r, color.g, color.b, color.a)
      love.graphics.draw(canvas, x or 0, y or 0, r or 0, sx or 1, sy or sx or 1)
    else
      love.graphics.setColor(color.r, color.g, color.b, color.a)
      love.graphics.setBlendMode('alpha', 'premultiplied')
      love.graphics.draw(canvas, x or 0, y or 0, r or 0, sx or 1, sy or sx or 1)
      love.graphics.setBlendMode('alpha')
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setShader()
  end

  init()

  return function()
    game.dt = love.timer.step()*game.timescale
    game.accumulator = game.accumulator + game.dt

    while game.accumulator >= game.rate do
      game.accumulator = game.accumulator - game.rate

      if love.event then
        love.event.pump()
        for name, a, b, c, d, e, f in love.event.poll() do
          if name == 'quit' then
            table.save('settings.txt', {
              sx = game.sx, sy = game.sy,
              display = game.display,
              window_w = game.window_w, window_h = game.window_h,
              main_canvas_leftover_w = game.main_canvas_leftover_w, main_canvas_leftover_h = game.main_canvas_leftover_h,
              fullscreen = game.fullscreen, scale = game.scale , max_scale = game.max_scale
            })
            return a or 0
          elseif name == 'keypressed' then
            input.keyboard_state[a] = true
            input.latest_input_type = 'keyboard'
          elseif name == 'keyreleased' then
            input.keyboard_state[a] = false
          elseif name == 'mousepressed' then
            input.mouse_state[c] = true
            input.latest_input_type = 'mouse'
          elseif name == 'mousereleased' then
            input.mouse_state[c] = false
          elseif name == 'wheelmoved' then
            if b == 1 then input.mouse_state.wheel_up = true end
            if b == -1 then input.mouse_state.wheel_down = true end
          elseif name == 'gamepadpressed' then
            input.gamepad_state[b] = true
            input.latest_input_type = 'gamepad'
          elseif name == 'gamepadreleased' then
            input.gamepad_state[b] = false
          elseif name == 'gamepadaxis' then
            input.gamepad_state[b] = c
          elseif name == 'joystickadded' then
            input.gamepad = a
          elseif name == 'joystickremoved' then
            input.gamepad = nil
          end
        end
      end

      draw_commands = {}
      game.step = game.step + 1
      game.time = game.time + game.rate
      system.update(game.rate)
      game:timer_update(game.rate)
      for _, s in pairs(sounds) do s:update(game.rate) end
      for _, h in ipairs(hitfx_objects) do h:hitfx_update(game.rate) end
      for _, t in ipairs(timer_objects) do t:timer_update(game.rate) end
      input:update()
      camera:update(game.rate)
      update(game.rate)
      for _, a in ipairs(area_objects) do a:update_vertices(game.rate) end
      for _, s in ipairs(stats_objects) do s:stats_post_update(game.rate) end
      for _, s in ipairs(state_objects) do s:state_post_update(game.rate) end
      input:post_update()
      for i = #hitfx_objects, 1, -1 do if hitfx_objects[i].dead then table.remove(hitfx_objects, i) end end
      for i = #timer_objects, 1, -1 do if timer_objects[i].dead then table.remove(timer_objects, i) end end
      for i = #area_objects, 1, -1 do if area_objects[i].dead then table.remove(area_objects, i) end end
      for i = #stats_objects, 1, -1 do if stats_objects[i].dead then table.remove(stats_objects, i) end end
      for i = #state_objects, 1, -1 do if state_objects[i].dead then table.remove(state_objects, i) end end
    end

    while game.framerate and love.timer.getTime() - last_frame < 1/game.framerate do
      love.timer.sleep(.0005)
    end

    last_frame = love.timer.getTime()
    if love.graphics and love.graphics.isActive() then
      love.graphics.origin()
      love.graphics.clear()
      game.frame = game.frame + 1
      love.graphics.setCanvas(main_canvas)
      love.graphics.clear()
        if game.layers then
          for _, layer in ipairs(game.layers) do -- draw to all layers' canvasses except when the layer depends on another layer being drawn (when .layers is true)
            if not layer.layers then
              local fixed_commands, not_fixed_commands = {}, {}
              for _, command in ipairs(draw_commands) do
                if command.layer == layer.name then
                  if command.fixed then
                    table.insert(fixed_commands, command)
                  else
                    table.insert(not_fixed_commands, command)
                  end
                end
              end
              table.stable_sort(fixed_commands, z_sort)
              table.stable_sort(not_fixed_commands, z_sort)
              love.graphics.setCanvas{layer.canvas, stencil=true}
              love.graphics.clear()
                camera:attach()
                for _, command in ipairs(not_fixed_commands) do
                  if type(command.type) == 'string' then
                    gfx[command.type](unpack(command.args))
                  else
                    command.type(unpack(command.args))
                  end
                end
                camera:detach()
                for _, command in ipairs(fixed_commands) do
                  if type(command.type) == 'string' then
                    gfx[command.type](unpack(command.args))
                  else
                    command.type(unpack(command.args))
                  end
                end
              love.graphics.setCanvas()
            end
          end
          for _, layer in ipairs(game.layers) do -- draw to all layers that have dependencies on other layers' canvasses having already been drawn to
            if layer.layers then
              if layer.shadow then
                love.graphics.setCanvas{layer.canvas, stencil=true}
                love.graphics.clear()
                  for _, l in ipairs(layer.layers) do
                    draw_canvas(game.layers[l].canvas, 0, 0, 0, 1, 1, colors.white[0], shaders.shadow, true)
                  end
                love.graphics.setCanvas()
              else -- not sure when this use case would be needed, will be filled when I make a game that uses it

              end
            end
          end
          for _, layer in ipairs(game.layers) do -- draw all layers' canvasses finally
            if layer.outline then
              layer.outline_shader:send('color', (layer.outline_color and layer.outline_color:to_table()) or colors.black[0]:to_table())
              layer.outline_shader:send('width', layer.outline)
              love.graphics.setCanvas{layer.outline_canvas, stencil=true}
              love.graphics.clear()
                draw_canvas(layer.canvas, 0, 0, 0, 1, 1, colors.white[0], layer.outline_shader)
              love.graphics.setCanvas()
              draw_canvas(layer.outline_canvas, layer.x or 0, layer.y or 0, 0, game.sx, game.sy)
              draw_canvas(layer.canvas, layer.x or 0, layer.y or 0, 0, game.sx, game.sy)
            else
              draw_canvas(layer.canvas, layer.x or 0, layer.y or 0, 0, game.sx, game.sy)
            end
          end
        end
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.setCanvas()
      love.graphics.setBlendMode('alpha', 'premultiplied')
      love.graphics.draw(main_canvas, game.main_canvas_leftover_w/2, game.main_canvas_leftover_h/2, 0, game.sx, game.sy)
      love.graphics.setBlendMode('alpha')
      love.graphics.present()
    end

    manual_gc(1e-3, 64, false)
    love.timer.sleep(game.sleep)
  end
end
