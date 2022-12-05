image = class:use()
function image:new(image_name)
  local image = love.graphics.newImage('assets/images/' .. image_name .. '.png')
  self.image = image
  self.w, self.h = image:getWidth(), image:getHeight()
end

function image:draw(layer, x, y, r, sx, sy, ox, oy, color, shader, z, fixed)
  local _r, g, b, a
  if color then
    _r, g, b, a = love.graphics.getColor()
    set_color(layer, color, z, fixed)
  end
  if shader then set_shader(layer, shader, z, fixed) end
  draw(layer, self.image, x, y, r or 0, sx or 1, sy or sx or 1, self.w*0.5 + (ox or 0), self.h*0.5 + (oy or 0), z, fixed)
  if shader then set_shader(layer, z, fixed) end
  if color then set_color_rgba(layer, _r, g, b, a, z, fixed) end
end

function load_images()
  images = {}
  for _, file in ipairs(system.enumerate_files('assets/images', '.png')) do images[file] = image(file) end
end


quad = class:use()
function quad:new(image, tile_w, tile_h, tile_coordinates)
  self.image = image
  self.quad = love.graphics.newQuad((tile_coordinates[1]-1)*tile_w, (tile_coordinates[2]-1)*tile_h, tile_w, tile_h, image.w, image.h)
  self.w = tile_w
  self.h = tile_h
end

function quad:draw(layer, x, y, r, sx, sy, ox, oy, z, fixed)
  draw(layer, self.image.image, self.quad, x, y, r or 0, sx or 1, sy or sx or 1, self.w*0.5 + (ox or 0), self.h*0.5 + (oy or 0), z, fixed)
end
