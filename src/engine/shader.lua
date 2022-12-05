shader = class:use()
function shader:new(vertex_name, fragment_name)
  self.shader = love.graphics.newShader('assets/shaders/' .. (vertex_name or 'default.vert'), 'assets/shaders/' .. fragment_name)
end

function shader:set()
  set_shader(self.shader)
end

function shader:unset()
  set_shader()
end

function shader:send(value, data)
  if type(data) == 'number' then self.shader:send(value, data)
  elseif data.type == 'canvas' then self.shader:send(value, data.canvas)
  elseif data.type == 'image' then self.shader:send(value, data.image)
  else self.shader:send(value, data) end
end

function load_shaders()
  shaders = {}
  for _, file in ipairs(system.enumerate_files('assets/shaders', '.frag')) do shaders[file] = shader(nil, file .. '.frag') end
end
