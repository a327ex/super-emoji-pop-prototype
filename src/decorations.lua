background = class:use(transform)
function background:new(x, y)
  self:transform(x, y)
end

function background:update(dt)
  rectangle('bg', self.x, self.y, game.w, game.h, 0, 0, colors.fg[0], nil, true)
end
