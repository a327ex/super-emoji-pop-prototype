-- A simple object that implements an area mixin.
-- Sometimes you might want to have multiple area mixins per object and this helps with that, since mixins assume singular use by default.
-- Ideally want the area mixin to be changed to something that accepts multiple areas, but for now this will do.
collider = class:use(transform, area)
function collider:new(x, y, shape_type, a, b, c, d, e)
  self:transform(x, y)
  self:area(shape_type, a, b, c, d, e)
end

function collider:update(dt)

end
