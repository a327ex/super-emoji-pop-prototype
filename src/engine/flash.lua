-- The argument passed in is the duration of the flash.
flash = class:use()
function flash:new(duration)
  self.duration = duration or 0.15
  self.timer = 0
  self.x = false
end


function flash:update(dt)
  self.timer = self.timer + dt
  if self.timer > self.duration then
    self.x = false
    self.timer = 0
  end
end


-- Activates the flash, this sets this object's .f attribute to true for the given duration.
function flash:flash(duration)
  self.x = true
  self.timer = 0
  self.duration = duration
end
