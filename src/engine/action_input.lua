-- Binds input from keyboard, mouse, gamepad (TODO: touch, Steam input) to actions.
-- Actions can then be used in gameplay code in an input device agnostic way.
-- For instance, self:bind('jump', {'key:x', 'key:space', button:a'}), will bind keyboard keys x and space, as well as gamepad's button a, to the 'jump' action.
-- In an update function, you could then do "if input.jump.pressed" to check if the button action has been pressed.
-- Possible states for actions: pressed, released, down.
-- A global object that implements this mixin called "input" is available by default.
action_input = class:use()
function action_input:new()
  self.actions = {}
  self.keyboard_state = {}
  self.previous_keyboard_state = {}
  self.gamepad_state = {}
  self.previous_gamepad_state = {}
  self.mouse_state = {}
  self.previous_mouse_state = {}
  self.gamepad = love.joystick.getJoysticks()[1]
  self.deadzone = 0.5
end

-- Binds an action to a set of controls. This allows you to code all gameplay code using action names rather than key/button names.
-- Controls come in the form '[type]:[key]', for instance:
-- input:bind('left', {'key:left', 'key:a', 'axis:leftx-', 'button:dpleft'})
-- input:bind('right', {'key:right', 'key:d', 'axis:leftx+', 'button:dpright'})
-- input:bind('up', {'key:up', 'key:w', 'axis:lefty-', 'button:dpup'})
-- input:bind('down', {'key:down', 'key:s', 'axis:lefty+', 'button:dpdown'})
-- input:bind('jump', {'key:x', 'key:space', button:a'})
-- Possible control types:
--   key - any LÖVE KeyConstant https://love2d.org/wiki/KeyConstant
--   mouse - a number representing a mouse button https://love2d.org/wiki/love.mouse.isDown
--   axis - a LÖVE GamepadAxis https://love2d.org/wiki/GamepadAxis, add + or - to the end for direction
--   button - a LÖVE GamepadButton https://love2d.org/wiki/GamepadButton
-- Repeated calls to this function given the same action will add new controls to it.
-- To reset an action's controls entirely call unbind_all. To remove a single control from it (such as when the player is rebinding keys) call unbind.
function action_input:bind(action, controls)
  if not self[action] then self[action] = {} end
  if not self[action].controls then self[action].controls = {} end
  for _, control in ipairs(controls) do table.insert(self[action].controls, control) end
  if not table.contains(self.actions, action) then table.insert(self.actions, action) end
end

-- Binds all keyboard keys to their own actions, so you can easily say "input.a.pressed" without having to bind it for every key.
function action_input:bind_all_keyboard_keys()
  local controls = {
    'key:a', 'key:b', 'key:c', 'key:d', 'key:e', 'key:f', 'key:g', 'key:h', 'key:i', 'key:j', 'key:k', 'key:l', 'key:m', 'key:n', 'key:o',
    'key:p', 'key:q', 'key:r', 'key:s', 'key:t', 'key:u', 'key:v', 'key:w', 'key:x', 'key:y', 'key:z', 'key:0', 'key:1', 'key:2', 'key:3',
    'key:4', 'key:5', 'key:6', 'key:7', 'key:8', 'key:9', 'key:space', 'key:!', 'key:"', 'key:#', 'key:$', 'key:&', "key:'", 'key:(', 'key:)',
    'key:*', 'key:+', 'key:,', 'key:-', 'key:.', 'key:/', 'key::', 'key:;', 'key:<', 'key:=', 'key:>', 'key:?', 'key:@', 'key:[', 'key:\\',
    'key:^', 'key:_', 'key:`', 'key:kp0', 'key:kp1', 'key:kp2', 'key:kp3', 'key:kp4', 'key:kp5', 'key:kp6', 'key:kp7', 'key:kp8', 'key:kp9',
    'key:kp.', 'key:kp,', 'key:kp/', 'key:kp*', 'key:kp-', 'key:kp+', 'key:kpenter', 'key:kp=', 'key:up', 'key:down', 'key:right', 'key:left',
    'key:home', 'key:end', 'key:pageup', 'key:pagedown', 'key:insert', 'key:backspace', 'key:tab', 'key:clear', 'key:return', 'key:delete',
    'key:f1', 'key:f2', 'key:f3', 'key:f4', 'key:f5', 'key:f6', 'key:f7', 'key:f8', 'key:f9', 'key:f10', 'key:f11', 'key:f12',
  }
  for _, control in ipairs(controls) do
    self:bind(control:right(':'), {control})
  end
end

-- Unbinds a single control from a given action.
function action_input:unbind(action, control)
  local control_index = table.contains(self[action].controls, control)
  if control_index then table.remove(self[action].controls, control_index) end
end

-- Unbinds all controls from a given action.
function action_input:unbind_all(action)
  self[action] = nil
end

function action_input:update(dt)
  for _, action in ipairs(self.actions) do
    self[action].pressed = false
    self[action].down = false
    self[action].released = false
  end

  for _, action in ipairs(self.actions) do
    for _, control in ipairs(self[action].controls) do
      action_type, key = control:left(':'), control:right(':')
      if action_type == 'key' then
        self[action].pressed = self[action].pressed or (self.keyboard_state[key] and not self.previous_keyboard_state[key])
        self[action].down = self[action].down or self.keyboard_state[key]
        self[action].released = self[action].released or (not self.keyboard_state[key] and self.previous_keyboard_state[key])
      elseif action_type == 'mouse' then
        if key == 'wheel_up' or key == 'wheel_down' then
          self[action].pressed = self.mouse_state[key]
        else
          self[action].pressed = self[action].pressed or (self.mouse_state[tonumber(key)] and not self.previous_mouse_state[tonumber(key)])
          self[action].down = self[action].down or self.mouse_state[tonumber(key)]
          self[action].released = self[action].released or (not self.mouse_state[tonumber(key)] and self.previous_mouse_state[tonumber(key)])
        end
      elseif action_type == 'axis' then
        if self.gamepad then
          if key:find('+') then key = key:left('+')
          elseif key:find('-') then key = key:left('-') end
          local value = self.gamepad:getGamepadAxis(key)
          local down = false
          if math.abs(value) >= self.deadzone then self.gamepad_state[key] = value
          else self.gamepad_state[key] = false end
          self[action].pressed = self[action].pressed or (self.gamepad_state[key] and not self.previous_gamepad_state[key])
          self[action].down = self[action].down or self.gamepad_state[key]
          self[action].released = self[action].released or (not self.gamepad_state[key] and self.previous_gamepad_state[key])
        end
      elseif action_type == 'button' then
        if self.gamepad then
          self[action].pressed = self[action].pressed or (self.gamepad_state[key] and not self.previous_gamepad_state[key])
          self[action].down = self[action].down or self.gamepad_state[key]
          self[action].released = self[action].released or (not self.gamepad_state[key] and self.previous_gamepad_state[key])
        end
      end
    end
  end
end

function action_input:post_update()
  self.previous_keyboard_state = table.copy(self.keyboard_state)
  self.previous_mouse_state = table.copy(self.mouse_state)
  self.previous_gamepad_state = table.copy(self.gamepad_state)
  self.mouse_state.wheel_up = false
  self.mouse_state.wheel_down = false
end
