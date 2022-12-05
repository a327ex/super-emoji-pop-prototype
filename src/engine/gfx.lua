-- All draw operations have an accompanying function without "gfx." that does the same thing but instead of drawing the command immediately queues it for later with the "draw_commands" table.
gfx = {}

function layers(...)
  game.layers = {}
  for _, layer_data in ipairs({...}) do
    local layer = {name = layer_data[1]}
    for k, v in pairs(layer_data) do
      if type(k) ~= 'number' then
        layer[k] = v
      end
    end
    layer.canvas = love.graphics.newCanvas(game.w, game.h, {msaa = game.smooth and 8 or 0})
    if layer.outline then
      layer.outline_canvas = love.graphics.newCanvas(game.w, game.h, {msaa = game.smooth and 8 or 0})
      layer.outline_shader = shader(nil, 'outline.frag')
      layer.outline_color = layer.outline_color or colors.black[0]
    end
    game.layers[layer.name] = layer
    table.insert(game.layers, layer)
  end
end

-- All operations after this is called will be affected by the transform.
function gfx.push(x, y, r, sx, sy)
  love.graphics.push()
  love.graphics.translate(x or 0, y or 0)
  love.graphics.scale(sx or 1, sy or sx or 1)
  love.graphics.rotate(r or 0)
  love.graphics.translate(-x or 0, -y or 0)
end

function push(layer, x, y, r, sx, sy, z, fixed)
  table.insert(draw_commands, {type = 'push', args = {x or 0, y or 0, r or 0, sx or 1, sy or sx or 1}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- All operations after this is called will not be affected by the transform set with graphics.push.
function gfx.pop()
  love.graphics.pop()
end

function pop(layer, z, fixed)
  table.insert(draw_commands, {type = 'pop', args = {}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.translate(x, y)
  love.graphics.translate(x or 0, y or 0)
end

function translate(layer, x, y, z, fixed)
  table.insert(draw_commands, {type = 'translate', args = {x or 0, y or 0}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.rotate(r)
  love.graphics.rotate(r or 0)
end

function rotate(layer, r, z, fixed)
  table.insert(draw_commands, {type = 'rotate', args = {r or 0}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.scale(sx, sy)
  love.graphics.scale(sx or 1, sy or sx or 1)
end

function rotate(layer, sx, sy, z, fixed)
  table.insert(draw_commands, {type = 'scale', args = {sx or 1, sy or sx or 1}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Prints text to the screen, alternative to using an object with a text mixin.
function gfx.print_text(text, font, x, y, r, sx, sy, ox, oy, color)
  local _r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  love.graphics.print(text, font.font, x, y, r or 0, sx or 1, sy or 1, ox or 0, oy or 0)
  if color then love.graphics.setColor(_r, g, b, a) end
end

function print_text(layer, text, font, x, y, r, sx, sy, ox, oy, color, z, fixed)
  table.insert(draw_commands, {type = 'print_text', args = {text, font, x, y, r, sx, sy, ox, oy, color}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Prints text to the screen centered on x, y, alternative to using an object with a text mixin.
function gfx.print_text_centered(text, font, x, y, r, sx, sy, ox, oy, color)
  local _r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  love.graphics.print(text, font.font, x, y, r or 0, sx or 1, sy or 1, (ox or 0) + font:get_text_width(text)/2, (oy or 0) + font.h/2)
  if color then love.graphics.setColor(_r, g, b, a) end
end

function print_text_centered(layer, text, font, x, y, r, sx, sy, ox, oy, color, z, fixed)
  table.insert(draw_commands, {type = 'print_text_centered', args = {text, font, x, y, r, sx, sy, ox, oy, color}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.shape(shape, color, line_width, ...)
  local r, g, b, a = love.graphics.getColor()
  if not color and not line_width then love.graphics[shape]("line", ...)
  elseif color and not line_width then
    love.graphics.setColor(color.r, color.g, color.b, color.a)
    love.graphics[shape]("fill", ...)
  else
    if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
    love.graphics.setLineWidth(line_width)
    love.graphics[shape]("line", ...)
    love.graphics.setLineWidth(1)
  end
  love.graphics.setColor(r, g, b, a)
end

-- Draws a rectangle of size w, h centered on x, y.
-- If rx, ry are passed in, then the rectangle will have rounded corners with radius of that size.
-- If color is passed in then the rectangle will be filled with that color (color is Color object)
-- If line_width is passed in then the rectangle will not be filled and will instead be drawn as a set of lines of the given width.
function gfx.rectangle(x, y, w, h, rx, ry, color, line_width)
  gfx.shape("rectangle", color, line_width, x - w/2, y - h/2, w, h, rx, ry)
end

function rectangle(layer, x, y, w, h, rx, ry, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'rectangle', args = {x, y, w, h, rx, ry, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Draws a rectangle of size w, h centered on x - w/2, y - h/2.
-- If rx, ry are passed in, then the rectangle will have rounded corners with radius of that size.
-- If color is passed in then the rectangle will be filled with that color (color is Color object)
-- If line_width is passed in then the rectangle will not be filled and will instead be drawn as a set of lines of the given width.
function gfx.rectanglel(x, y, w, h, rx, ry, color, line_width)
  gfx.shape("rectangle", color, line_width, x, y, w, h, rx, ry)
end

function rectanglel(layer, x, y, w, h, rx, ry, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'rectanglel', args = {x, y, w, h, rx, ry, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Draws a dashed rectangle of size w, h centerd on x, y.
-- dash_size and gap_size correspond to the dimensions of the dashing behavior.
function gfx.dashed_rectangle(x, y, w, h, dash_size, gap_size, color, line_width)
  gfx.dashed_line(x - w/2, y - h/2, x + w/2, y - h/2, dash_size, gap_size, color, line_width)
  gfx.dashed_line(x - w/2, y - h/2, x - w/2, y + h/2, dash_size, gap_size, color, line_width)
  gfx.dashed_line(x - w/2, y + h/2, x + w/2, y + h/2, dash_size, gap_size, color, line_width)
  gfx.dashed_line(x + w/2, y - h/2, x + w/2, y + h/2, dash_size, gap_size, color, line_width)
end

-- Draws an isosceles triangle with size w, h centered on x, y pointed to the right (angle 0).
-- If color is passed in then the triangle will be filled with that color (color is Color object)
-- If line_width is passed in then the triangle will not be filled and will instead be drawn as a set of lines of the given width.
function gfx.triangle(x, y, w, h, color, line_width)
  local x1, y1 = x + h/2, y
  local x2, y2 = x - h/2, y - w/2
  local x3, y3 = x - h/2, y + w/2
  gfx.polygon({x1, y1, x2, y2, x3, y3}, color, line_width)
end

function triangle(layer, x, y, w, h, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'triangle', args = {x, y, w, h, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Draws an equilateral triangle with size w centered on x, y pointed to the right (angle 0).
-- If color is passed in then the triangle will be filled with that color (color is Color object)
-- If line_width is passed in then the triangle will not be filled and will instead be drawn as a set of lines of the given width.
function gfx.triangle_equilateral(x, y, w, r, color, line_width)
  local h = math.sqrt(math.pow(w, 2) - math.pow(w/2, 2))
  if r then gfx.push(x, y, r) end
  gfx.triangle(x, y, w, h, color, line_width)
  if r then gfx.pop() end
end

function triangle_equilateral(layer, x, y, w, r, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'triangle_equilateral', args = {x, y, w, r, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Draws a circle of radius r centered on x, y.
-- If color is passed in then the circle will be filled with that color (color is Color object)
-- If line_width is passed in then the circle will not be filled and will instead be drawn as a set of lines of the given width.
function gfx.circle(x, y, r, color, line_width)
  gfx.shape("circle", color, line_width, x, y, r)
end

function circle(layer, x, y, r, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'circle', args = {x, y, r, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Draws an arc of radius r from angle r1 to angle r2 centered on x, y.
-- If color is passed in then the arc will be filled with that color (color is Color object)
-- If line_width is passed in then the arc will not be filled and will instead be drawn as a set of lines of the given width.
function gfx.arc(arctype, x, y, r, r1, r2, color, line_width)
  gfx.shape("arc", color, line_width, arctype, x, y, r, r1, r2)
end

function arc(layer, x, y, r, r1, r2, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'arc', args = {x, y, r, r1, r2, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Draws a polygon with the given points.
-- If color is passed in then the polygon will be filled with that color (color is Color object)
-- If line_width is passed in then the polygon will not be filled and will instead be drawn as a set of lines of the given width.
function gfx.polygon(vertices, color, line_width)
  gfx.shape("polygon", color, line_width, vertices)
end

function polygon(layer, vertices, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'polygon', args = {vertices, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Draws a rounded polygon with the given points and with corners of radius rs.
function gfx.rounded_polygon(vertices, rs, color, line_width)
  
end

-- Draws a line with the given points.
function gfx.line(x1, y1, x2, y2, color, line_width)
  local r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  if line_width then love.graphics.setLineWidth(line_width) end
  love.graphics.line(x1, y1, x2, y2)
  love.graphics.setColor(r, g, b, a)
  love.graphics.setLineWidth(1)
end

function line(layer, x1, y1, x2, y2, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'line', args = {x1, y1, x2, y2, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Draws a series of connected lines with the given points.
function gfx.polyline(vertices, color, line_width) 
  local r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  if line_width then love.graphics.setLineWidth(line_width) end
  love.graphics.line(unpack(vertices))
  love.graphics.setColor(r, g, b, a)
  love.graphics.setLineWidth(1)
end

function polyline(layer, vertices, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'polyline', args = {vertices, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.cross(x, y, w, r, color, line_width)
  if r then gfx.push(x, y, r) end
    gfx.line(x - w/2, y, x + w/2, y, color, line_width)
    gfx.line(x, y - w/2, x, y + w/2, color, line_width)
  if r then gfx.pop() end
end

function cross(layer, x, y, w, r, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'cross', args = {x, y, w, r, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Draws a series of connected lines with rounded corners of radius rs with the given points.
function gfx.rounded_polyline(vertices, color, line_width) 
  local r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  if line_width then love.graphics.setLineWidth(line_width) end

  local rs = line_width/2
  for i = 1, #vertices, 2 do
    local x1, y1, x2, y2 = vertices[i-2], vertices[i-1], vertices[i], vertices[i+1], vertices[i+2], vertices[i+3]
    if x1 and y1 and x2 and y2 then
      gfx.rounded_line(x1, y1, x2, y2, color, line_width)
    end
  end

  love.graphics.setColor(r, g, b, a)
  love.graphics.setLineWidth(1)
end

function rounded_polyline(layer, vertices, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'rounded_polyline', args = {vertices, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Draws a line with rounded ends with the given points.
-- If color is passed in then the line will be filled with that color (color is Color object)
-- If line_width is passed in then the line will not be filled and will instead be drawn as a set of lines of the given width.
function gfx.rounded_line(x1, y1, x2, y2, color, line_width)
  local x, y = (x1+x2)/2, (y1+y2)/2
  gfx.push(x, y, math.angle_to(x1, y1, x2, y2))
  gfx.rectangle(x, y, math.length(x2-x1, y2-y1), line_width/2, line_width/4, line_width/4, color)
  gfx.pop()
end

function rounded_line(layer, x1, y1, x2, y2, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'rounded_line', args = {x1, y1, x2, y2, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Draws a dashed line with the given points.
-- dash_size and gap_size correspond to the dimensions of the dashing behavior.
-- If color is passed in then the lines will be filled with that color (color is Color object)
-- If line_width is passed in then the lines will not be filled and will instead be drawn as a set of lines of the given width.
function gfx.dashed_line(x1, y1, x2, y2, dash_size, gap_size, color, line_width)
  local r, g, b, a = love.graphics.getColor()
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  if line_width then love.graphics.setLineWidth(line_width) end
  local dx, dy = x2-x1, y2-y1
  local an, st = math.atan2(dy, dx), dash_size + gap_size
  local len = math.sqrt(dx*dx + dy*dy)
  local nm = (len-dash_size)/st
  love.graphics.push()
    love.graphics.translate(x1, y1)
    love.graphics.rotate(an)
    for i = 0, nm do love.graphics.line(i*st, 0, i*st + dash_size, 0) end
    love.graphics.line(nm*st, 0, nm*st + dash_size, 0)
  love.graphics.pop()
end

function dashed_line(layer, x1, y1, x2, y2, dash_size, gap_size, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'dashed_line', args = {x1, y1, x2, y2, dash_size, gap_size, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Draws a dashed line with rounded ends with the given points.
-- dash_size and gap_size correspond to the dimensions of the dashing behavior.
-- If color is passed in then the lines will be filled with that color (color is Color object)
-- If line_width is passed in then the lines will not be filled and will instead be drawn as a set of lines of the given width.
function gfx.dashed_rounded_line(x1, y1, x2, y2, dash_size, gap_size, color, line_width)
  if color then love.graphics.setColor(color.r, color.g, color.b, color.a) end
  if line_width then love.graphics.setLineWidth(line_width) end
  local dx, dy = x2-x1, y2-y1
  local an, st = math.atan2(dy, dx), dash_size + gap_size
  local len = math.sqrt(dx*dx + dy*dy)
  local nm = (len-dash_size)/st
  love.graphics.push()
    love.graphics.translate(x1, y1)
    love.graphics.rotate(an)
    for i = 0, nm do
      love.graphics.push()
      love.graphics.translate(i*st, 0)
      love.graphics.rotate(math.angle(i*st, 0, i*st + dash_size, 0))
      love.graphics.translate(-i*st, -0)
      gfx.shape("rectangle", color, nil, i*st, 0, math.length((i*st + dash_size)-(i*st), 0-0), line_width/2, line_width/4, line_width/4)
      love.graphics.pop()
    end
    love.graphics.push()
    love.graphics.translate(nm*st, 0)
    love.graphics.rotate(math.angle(nm*st, 0, nm*st + dash_size, 0))
    love.graphics.translate(-nm*st, -0)
    gfx.shape("rectangle", color, nil, nm*st, 0, math.length((nm*st + dash_size)-(nm*st), 0-0), line_width/2, line_width/4, line_width/4)
    love.graphics.pop()
  love.graphics.pop()
end

function dashed_rounded_line(layer, x1, y1, x2, y2, dash_size, gap_size, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'dashed_rounded_line', args = {x1, y1, x2, y2, dash_size, gap_size, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Draws an ellipse with radius rx, ry centered on x, y.
-- If color is passed in then the ellipse will be filled with that color
-- If line_width is passed in then the ellipse will not be filled and will instead be drawn as a set of lines of the given width.
function gfx.ellipse(x, y, rx, ry, color, line_width)
  gfx.shape("ellipse", color, line_width, x, y, rx, ry)
end

function ellipse(layer, x, y, rx, ry, color, line_width, z, fixed)
  table.insert(draw_commands, {type = 'ellipse', args = {x, y, rx, ry, color, line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Sets the currently active shader, the passed in argument should be a Shader object.
function gfx.set_shader(shader)
  if not shader then love.graphics.setShader()
  else love.graphics.setShader(shader.shader) end
end

function set_shader(layer, shader, z, fixed)
  table.insert(draw_commands, {type = 'set_shader', args = {shader}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Sets the currently active canvas, the passed in argument should be a Canvas object.
function gfx.set_canvas(canvas)
  if not canvas then love.graphics.setCanvas()
  else love.graphics.setCanvas{canvas.canvas, stencil=true} end
end

function set_canvas(layer, canvas, z, fixed)
  table.insert(draw_commands, {type = 'set_canvas', args = {canvas}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Clears the currently active canvas.
function gfx.clear()
  love.graphics.clear()
end

function clear(layer, z, fixed)
  table.insert(draw_commands, {type = 'clear', args = {}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Sets the currently active blend mode.
function gfx.set_blend_mode(mode, alpha_mode)
  love.graphics.setBlendMode(mode, alpha_mode)
end

function set_blend_mode(layer, mode, alpha_mode, z, fixed)
  table.insert(draw_commands, {type = 'set_blend_mode', args = {mode, alpha_mode}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Sets the currently active color, the passed in argument should be a Color object.
function gfx.set_color(color)
  love.graphics.setColor(color.r, color.g, color.b, color.a)
end

function set_color(layer, color, z, fixed)
  table.insert(draw_commands, {type = 'set_color', args = {color}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.set_color_rgba(r, g, b, a)
  love.graphics.setColor(r, g, b, a)
end

function set_color_rgba(layer, r, g, b, a, z, fixed)
  table.insert(draw_commands, {type = 'set_color_rgba', args = {r, g, b, a}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.get_color()
  return love.graphics.getColor()
end

function get_color(layer, z, fixed)
  table.insert(draw_commands, {type = 'get_color', args = {}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Sets the currently active background color, the passed in argument should be a Color object.
function gfx.set_background_color(color)
  love.graphics.setBackgroundColor(color.r, color.g, color.b, color.a)
end

function set_background_color(layer, color, z, fixed)
  table.insert(draw_commands, {type = 'set_background_color', args = {color}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.set_line_width(line_width)
  love.graphics.setLineWidth(line_width)
end

function set_line_width(layer, line_width, z, fixed)
  table.insert(draw_commands, {type = 'set_line_width', args = {line_width}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Sets the line style, possible values are 'rough' and 'smooth'.
function gfx.set_line_style(style)
  love.graphics.setLineStyle(style)
end

function set_line_style(layer, style, z, fixed)
  table.insert(draw_commands, {type = 'set_line_style', args = {style}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Sets the default filter mode, possible values are 'nearest' and 'linear'.
function gfx.set_default_filter(min, max)
  love.graphics.setDefaultFilter(min, max)
end

function set_default_filter(layer, min, max, z, fixed)
  table.insert(draw_commands, {type = 'set_default_filter', args = {min, max}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.set_mouse_visible(value)
  love.mouse.setVisible(value)
end

function set_mouse_visible(layer, value, z, fixed)
  table.insert(draw_commands, {type = 'set_mouse_visible', args = {value}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.stencil(stencilfunction, action, value, keepvalues)
  love.graphics.stencil(stencilfunction, action, value, keepvalues)
end

function stencil(layer, stencilfunction, action, value, keepvalues, z, fixed)
  table.insert(draw_commands, {type = 'stencil', args = {stencilfunction, action, value, keepvalues}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.set_stencil_test(comparemode, comparevalue)
  love.graphics.setStencilTest(comparemode, comparevalue)
end

function set_stencil_test(layer, comparemode, comparevalue, z, fixed)
  table.insert(draw_commands, {type = 'set_stencil_test', args = {comparemode, comparevalues}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.draw(drawable, x, y, r, sx, sy, ox, oy)
  love.graphics.draw(drawable, x, y, r, sx, sy, ox, oy)
end

function draw(layer, drawable, x, y, r, sx, sy, ox, oy, z, fixed)
  table.insert(draw_commands, {type = 'draw', args = {drawable, x, y, r, sx, sy, ox, oy}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.draw_quad(drawable, quad, x, y, r, sx, sy, ox, oy)
  love.graphics.draw(drawable, quad, x, y, r, sx, sy, ox, oy)
end

function draw_quad(layer, drawable, quad, x, y, r, sx, sy, ox, oy, z, fixed)
  table.insert(draw_commands, {type = 'draw_quad', args = {drawable, quad, x, y, r, sx, sy, ox, oy}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

-- Draws the image masked by a shape, meaning that only parts inside (or outside) the shape that intersects the image are drawn.
-- By default only parts that intersect with the shape are drawn, pass the third argument as true to make it so that only parts that don't intersect are drawn.
-- action is a function that draws the image.
-- mask_action is a function that draws the shape.
function gfx.draw_with_mask(action, mask_action, invert_mask)
  love.graphics.stencil(function() mask_action() end)
  if not invert_mask then love.graphics.setStencilTest('greater', 0)
  else love.graphics.setStencilTest('notequal', 1) end
  action()
  love.graphics.setStencilTest()
end

function draw_with_mask(layer, action, mask_action, invert_mask, z, fixed)
  table.insert(draw_commands, {type = 'stencil', args = {mask_action}, fixed = fixed, layer = layer or 'default', z = z or 0})
  if not invert_mask then table.insert(draw_commands, {type = 'set_stencil_test', args = {'greater', 0}, fixed = fixed, layer = layer or 'default', z = z or 0})
  else table.insert(draw_commands, {type = 'set_stencil_test', args = {'notequal', 1}, fixed = fixed, layer = layer or 'default', z = z or 0}) end
  table.insert(draw_commands, {type = function() action() end, args = {}, fixed = fixed, layer = layer or 'default', z = z or 0})
  table.insert(draw_commands, {type = 'set_stencil_test', args = {}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

stencil_mask_shader = love.graphics.newShader[[
vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc) {
  vec4 t = Texel(texture, tc);
  if (t.a == 0.0) {
    discard;
  }
  return t;
}
]]

-- Draws the second image on top of the first, but only the portions of the first image that aren't transparent are drawn.
-- This essentially applies the second image as a texture on top of the shape of the first.
-- action1 and action2 are functions that draw the images.
-- gfx.texture(function() player_image:draw(player.x, player.y) end, function() gradient_image:draw(player.x, player.y) end) -> draws the player with a gradient applied to it
function gfx.texture(action1, action2)
  love.graphics.stencil(function() love.graphics.setShader(stencil_mask_shader); action1(); love.graphics.setShader() end, 'replace', 1)
  love.graphics.setStencilTest('greater', 0)
  action2()
  love.graphics.setStencilTest()
end

function texture(layer, action1, action2, z, fixed)
  table.insert(draw_commands, {type = 'stencil', args = {function() love.graphics.setShader(stencil_mask_shader); action1(); love.graphics.setShader() end, 'replace', 1}, fixed = fixed, layer = layer or 'default', z = z or 0})
  table.insert(draw_commands, {type = 'set_stencil_test', args = {'greater', 0}, fixed = fixed, layer = layer or 'default', z = z or 0})
  table.insert(draw_commands, {type = function() action2() end, args = {}, fixed = fixed, layer = layer or 'default', z = z or 0})
  table.insert(draw_commands, {type = 'set_stencil_test', args = {}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.attach(px, py)
  camera:attach(px, py)
end

function attach(layer, px, py, z, fixed)
  table.insert(draw_commands, {type = 'attach', args = {px, py}, fixed = fixed, layer = layer or 'default', z = z or 0})
end

function gfx.detach()
  camera:detach()
end

function detach(layer, z, fixed)
  table.insert(draw_commands, {type = 'detach', args = {}, fixed = fixed, layer = layer or 'default', z = z or 0})
end
