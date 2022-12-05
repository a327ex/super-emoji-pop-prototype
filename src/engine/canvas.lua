canvas = class:use()
function canvas:new(w, h, stencil, flat)
  self.w, self.h = w or game.w, h or game.h
  self.stencil = stencil
  self.flat = flat
  self.canvas = love.graphics.newCanvas(self.w, self.h, {msaa = game.smooth and 8 or 0})
end

function canvas:get_size()
  return self.w, self.h
end

function canvas:draw_to(layer, action, z, fixed)
  set_canvas(layer, z, fixed)
  clear(layer, z, fixed)
  table.insert(draw_commands, {type = action(), fixed = fixed, layer = layer or 'default', z = z or 0})
  set_canvas(layer, z, fixed)
end

local function draw_canvas(layer, canvas, x, y, r, sx, sy, color, shader, flat, z, fixed)
  if self.shader or shader then set_shader(layer, self.shader or shader, z, fixed) end
  if self.flat or flat then
    set_color(layer, self.color or color, z, fixed)
    draw(layer, canvas, self.x or x or 0, self.y or y or 0, r or 0, self.sx or sx or 1, self.sy or sy or sx or 1, nil, nil, z, fixed)
  else
    set_color(layer, self.color or color, z, fixed)
    set_blend_mode(layer, 'alpha', 'premultiplied', z, fixed)
    draw(layer, canvas, self.x or x or 0, self.y or y or 0, r or 0, self.sx or sx or 1, self.sy or sy or sx or 1, nil, nil, z, fixed)
    set_blend_mode(layer, 'alpha', z, fixed)
  end
  set_color(layer, colors.white[0], z, fixed)
  set_shader(layer, z, fixed)
end

function canvas:draw(layer, x, y, r, sx, sy, color, shader, flat, z, fixed)
  if self:is(outline) then
    shaders.outline:send('color', self.outline_color:to_table())
    shaders.outline:send('width', self.outline_width)
    self.outline_canvas:draw_to(function()
      draw_canvas(layer, self.canvas, 0, 0, 0, 1, 1, colors.white, shaders.outline, flat, z, fixed)
    end)
    draw_canvas(layer, self.outline_canvas, x, y, r, sx, sy, nil, nil, flat, z, fixed)
    draw_canvas(layer, self.canvas, x, y, r, sx, sy, color, shader, flat, z, fixed)
  else
    draw_canvas(layer, self.canvas, x, y, r, sx, sy, color, shader, flat, z, fixed)
  end
end
