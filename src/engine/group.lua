-- This is a container in object instead of mixin form.
group = class:use(container)
function group:new(weak)
  self:container(weak)
end
