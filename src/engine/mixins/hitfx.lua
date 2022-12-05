-- Whenever an object is interacted with it's a good idea to either pull on a spring attached to its scale, or to flash it to signal that the interaction went through.
-- This is a combination of both springs and flashes put together to create that effect.
-- Use this as a mixin on a game object.
hitfx = class:use()
function hitfx:hitfx()
  self.springs = {}
  self.flashes = {}
end

function hitfx:hitfx_update(dt)
  for _, spring in pairs(self.springs) do spring:update(dt) end
  for _, flash in pairs(self.flashes) do flash:update(dt) end
end

-- Sets a new hit effect with the given name and with the given variables.
-- x, k and d correspond to spring struct variables, while flash_duration corresponds to how long the flash should last for in seconds.
-- self:add_hitfx('hit', 1, nil, nil, 0.15)
-- To get the spring's or flashes' value you would access it through self.hitfx.springs.hit.x or self.hitfx.flashes.hit.f. 
-- .x is the spring value, while .f is a boolean that says if it's currently flashing or not
function hitfx:hitfx_add(name, x, k, d, flash_duration)
  self.springs[name] = spring(x, k, d)
  self.flashes[name] = flash(flash_duration)
end

-- Uses both the spring and flash effect. self:hitfx_add must have been called first with the given effect name.
-- self:use_hitfx('hit', 2, nil, nil, 0.3)
function hitfx:hitfx_use(name, x, k, d, flash_duration)
  self.springs[name]:pull(x, k, d)
  self.flashes[name]:flash(flash_duration)
end

-- Pulls the spring with the given name, must have been added before with self:hitfx_add.
function hitfx:pull(name, ...)
  self.springs[name]:pull(...)
end

-- Flashes the flash with the given name, must have been added before with self:hitfx_add.
function hitfx:flash(name, ...)
  self.flashes[name]:flash(...)
end
