timer = class:use()
function timer:new() self:timer() end
function timer:timer()
  self.timers = {}
end

local empty_function = function() end

-- Calls the action every frame until it's cancelled via :cancel.
-- The tag must be passed in otherwise there will be no way to stop this from running.
-- If after is passed in then it is called after the run is cancelled.
function timer:run(action, after, tag)
  local tag = tag or random:uid()
  self.timers[tag] = {type = "run", timer = 0, after = after or empty_function, action = action}
end

-- Calls the action after delay seconds.
-- Or calls the action after the condition is true.
-- If tag is passed in then any other timer actions with the same tag are automatically cancelled.
-- :after(2, function() print(1) end) -> prints 1 after 2 seconds
-- :after(function() return self.should_print_1 end, function() print(1) end) -> prints 1 after self.should_print_1 is set to true
function timer:after(delay, action, tag)
  local tag = tag or random:uid()
  if type(delay) == "number" or type(delay) == "table" then
    self.timers[tag] = {type = "after", timer = 0, unresolved_delay = delay, delay = self:resolve_delay(delay), action = action}
  else
    self.timers[tag] = {type = "conditional_after", condition = delay, action = action}
  end
end

-- Calls the action every delay seconds if the condition is true.
-- If the condition isn't true when delay seconds are up then it waits and only performs the action and resets the timer when that happens.
-- If times is passed in then it only calls action for that amount of times.
-- If after is passed in then it is called after the last time action is called.
-- If tag is passed in then any other timer actions with the same tag are automatically cancelled.
-- :cooldown(2, function() return #self:get_objects_in_shape(self.attack_sensor, enemies) > 0 end, function() self:attack() end) -> only attacks when 2 seconds have passed and there are more than 0 enemies around
function timer:cooldown(delay, condition, action, times, after, tag)
  local tag = tag or random:uid()
  self.timers[tag] = {type = "cooldown", timer = 0, unresolved_delay = delay, delay = self:resolve_delay(delay), condition = condition, action = action, times = times or 0, max_times = times or 0,
    after = after or empty_function, multiplier = 1}
end

-- Calls the action every delay seconds.
-- Or calls the action once every time the condition becomes true.
-- If times is passed in then it only calls action for that amount of times.
-- If after is passed in then it is called after the last time action is called.
-- If tag is passed in then any other timer actions with the same tag are automatically cancelled.
-- :every(2, function() print(1) end) -> prints 1 every 2 seconds
-- :every(2, function() print(1) end, 5, function() print(2) end) -> prints 1 every 2 seconds 5 times, and then prints 2
-- :every(function() return player.hit end, function() print(1) end) -> prints 1 every time the player is hit
-- :every(function() return player.grounded end, function() print(1), 5, function() print(2) end) -> prints 1 every time the player becomes grounded 5 times, and then prints 2
-- Note that if using this as a condition, the action will only be timered when the condition jumps from being false to true.
-- If the condition remains true for multiple frames then the action won't be timered further, unless it becomes false and then becomes true again.
function timer:every(delay, action, times, after, tag)
  local tag = tag or random:uid()
  if type(delay) == "number" or type(delay) == "table" then
    self.timers[tag] = {type = "every", timer = 0, unresolved_delay = delay, delay = self:resolve_delay(delay), action = action, times = times or 0, max_times = times or 0, after = after or empty_function, multiplier = 1}
  else
    self.timers[tag] = {type = "conditional_every", condition = delay, last_condition = false, action = action, times = times or 0, max_times = times or 0, after = after or empty_function}
  end
end

-- Same as every except the action is called immediately when this function is called, and then every delay seconds.
function timer:every_immediate(delay, action, times, after, tag)
  local tag = tag or random:uid()
  self.timers[tag] = {type = "every", timer = 0, unresolved_delay = delay, delay = self:resolve_delay(delay), action = action, times = times or 0, max_times = times or 0, after = after or empty_function, multiplier = 1}
  action()
end

-- Calls the action every frame for delay seconds.
-- Or calls the action every frame the condition is true.
-- If after is passed in then it is called after the duration ends or after the condition becomes false.
-- If tag is passed in then any other timer actions with the same tag are automatically cancelled.
-- :during(5, function() print(random:float(0, 100)) end)
-- :during(function() return self.should_print_rng_float end, function() print(random:float(0, 100)) end) -> prints the rng float as long as self.should_print_rng_float is true
function timer:during(delay, action, after, tag)
  local tag = tag or random:uid()
  if type(delay) == "number" or type(delay) == "table" then
    self.timers[tag] = {type = "during", timer = 0, unresolved_delay = delay, delay = self:resolve_delay(delay), action = action, after = after or empty_function}
  elseif type(delay) == "function" then
    self.timers[tag] = {type = "conditional_during", condition = delay, last_condition = false, action = action, after = after or empty_function}
  end
end

-- Tweens the target's values specified by the source table for delay seconds using the given tweening method.
-- All tween methods can be found in the math/math file.
-- If after is passed in then it is called after the duration ends.
-- If tag is passed in then any other timer actions with the same tag are automatically cancelled.
-- :tween(0.2, self, {sx = 0, sy = 0}, math.linear) -> tweens this object's scale variables to 0 linearly over 0.2 seconds
-- :tween(0.2, self, {sx = 0, sy = 0}, math.linear, function() self.dead = true end) -> tweens this object's scale variables to 0 linearly over 0.2 seconds and then kills it
function timer:tween(delay, target, source, method, after, tag)
  local tag = tag or random:uid()
  local initial_values = {}
  for k, _ in pairs(source) do initial_values[k] = target[k] end
  self.timers[tag] = {type = "tween", timer = 0, unresolved_delay = delay, delay = self:resolve_delay(delay), target = target, initial_values = initial_values, source = source, method = method or math.linear,
    after = after or empty_function}
end

-- Cancels a timer action based on its tag.
-- This is automatically called if repeated tags are given to timer actions.
function timer:cancel(tag)
  if self.timers[tag] and self.timers[tag].type == "run" then
    self.timers[tag].after()
  end
  self.timers[tag] = nil
end

-- Resets the timer for a tag.
-- Useful when you need to start counting that tag from 0 after an event happens.
function timer:reset(tag)
  self.timers[tag].timer = 0
end

-- Returns the delay of a given tag.
-- This is useful when delays are set randomly (every(timer, {2, 4}, ...) would set the delay at a random number between 2 and 4) and you need to know what the value chosen was.
function timer:get_delay(tag)
  return self.timers[tag].delay
end

-- Returns the current iteration of an every timer action with the given tag.
-- Useful if you need to know that its the nth time an every action has been called.
function timer:get_every_iteration(tag)
  return self.timers[tag].max_times - self.timers[tag].times 
end

-- Sets a multiplier for a given tag.
-- This is useful when you need the event to happen in a varying interval, like based on the player's attack speed, which might change every frame based on buffs.
-- Call this on the update function with the appropriate multiplier.
function timer:set_multiplier(tag, multiplier)
  if not self.timers[tag] then return end
  self.timers[tag].multiplier = multiplier or 1
end

function timer:get_multiplier(tag)
  if not self.timers[tag] then return end
  return self.timers[tag].multiplier
end

-- Returns the elapsed time of a given timer as a number between 0 and 1.
-- Useful if you need to know where you currently are in the duration of a during call.
function timer:get_during_elapsed_time(tag)
  if not self.timers[tag] then return end
  return self.timers[tag].timer/self.timers[tag].delay
end

-- Returns the elapsed time of a given timer as well as its delay.
-- Useful if you need to know where you currently are in the duration of an every call.
function timer:get_timer_and_delay(tag)
  if not self.timers[tag] then return end
  return self.timers[tag].timer, self.timers[tag].delay
end

function timer:resolve_delay(delay)
  if type(delay) == "table" then
    return random:float(delay[1], delay[2])
  else
    return delay
  end
end

function timer:timer_update(dt)
  for tag, t in pairs(self.timers) do
    if t.timer then t.timer = t.timer + dt end
    if t.type == "run" then
      t.action()
    elseif t.type == "cooldown" then
      if t.timer > t.delay*t.multiplier and t.condition() then
        t.action()
        t.timer = 0
        t.delay = self:resolve_delay(t.unresolved_delay)
        if t.times > 0 then
          t.times = t.times - 1
          if t.times <= 0 then
            t.after()
            self.timers[tag] = nil
          end
        end
      end
    elseif t.type == "after" then
      if t.timer > t.delay then
        t.action()
        self.timers[tag] = nil
      end
    elseif t.type == "conditional_after" then
      if t.condition() then
        t.action()
        self.timers[tag] = nil
      end
    elseif t.type == "every" then
      if t.timer > t.delay*t.multiplier then
        t.action()
        t.timer = t.timer - t.delay*t.multiplier
        t.delay = self:resolve_delay(t.unresolved_delay)
        if t.times > 0 then
          t.times = t.times - 1
          if t.times <= 0 then
            t.after()
            self.timers[tag] = nil
          end
        end
      end
    elseif t.type == "conditional_every" then
      local condition = t.condition()
      if condition and not t.last_condition then
        t.action()
        if t.times > 0 then
          t.times = t.times - 1
          if t.times <= 0 then
            t.after()
            self.timers[tag] = nil
          end
        end
      end
      t.last_condition = condition
    elseif t.type == "during" then
      t.action(dt)
      if t.timer > t.delay then
        t.after()
        self.timers[tag] = nil
      end
    elseif t.type == "conditional_during" then
      local condition = t.condition()
      if condition then
        t.action()
      end
      if t.last_condition and not condition then
        t.after()
      end
      t.last_condition = condition
    elseif t.type == "tween" then
      for k, v in pairs(t.source) do
        t.target[k] = math.lerp(t.method(t.timer/t.delay), t.initial_values[k], v)
      end
      if t.timer > t.delay then
        t.after()
        self.timers[tag] = nil
      end
    end
  end
end
