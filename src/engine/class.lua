-- This is a class system that has only mixins and no inheritance.
-- Create a new class and an instance:
--   a = class:use()
--   function a:print1() print(1) end
--   a1 = a()
--   a1:print1() -> prints 1
--
-- Create a new class and instance that uses the functions of another class as a mixin:
--   b = class:use(a)
--   function b:print2() print(2) end
--   b1 = b()
--   b1:print2() -> prints 2
--   b1:print1() -> prints 1
--
-- The use function can take in multiple other classes:
--   d = class:use(a, b, c)
--
-- Class function names must not collide. An error will be thrown if this happens.
-- In the future might change to a less strict setup, but for now it being this strict is better.
class = {}
class.__index = class
function class:new() end

function class:use(...)
  local c = {}
  c.__is = {}
  c.__is[c] = true

  local mixins = {...}
  for _, mixin in ipairs(mixins) do
    c.__is[mixin] = true
    for k, v in pairs(mixin) do
      if k ~= 'new' and not k:find('__') then
        if c[k] then
          error('collision on function or attribute name "' .. k .. '"')
        elseif c[k] == nil and type(v) == 'function' then
          c[k] = v
        end
      end
    end
  end

  c.__index = c
  c.__class = c
  setmetatable(c, self)
  return c
end

function class:is(c)
  return self.__is[c]
end

function class:__call(...)
  local instance = setmetatable({}, self)
  instance.id = random and random:uid() or 0
  instance:new(...)
  if instance:is(area) then table.insert(area_objects, instance) end
  if instance:is(hitfx) then table.insert(hitfx_objects, instance) end
  if instance:is(state) then table.insert(state_objects, instance) end
  if instance:is(stats) then table.insert(stats_objects, instance) end
  if instance:is(timer) then table.insert(timer_objects, instance) end
  return instance
end
