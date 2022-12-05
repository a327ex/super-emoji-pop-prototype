-- Adds a finite state machine to the game object:
--[[
  -- self:state('idle', {'idle', 'attack', 'move'})

  function update(dt)
    if enemy.states.attack.enter then
      -- do attack actions once
    end

    if enemy.states.move.active then
      enemy:follow(player)
      if enemy:distance_to(player) < 32 then
        enemy:go('attack')
      end
    end
  end
]]--
state = class:use()
function state:state(initial_state, states)
  self.states = {}
  for _, state in ipairs(states or {'default'}) do self.states[state] = {enter = false, leave = false, active = false} end
  self:go(initial_state or 'default')
end

-- Sets the called state as the currently active one and sets the previously active state as unactive.
-- For instance, calling self:go('level_1') sets self.state.level_1.enter to true for 1 frame and self.state.level_1.active to true until another state becomes active.
-- It also sets self.state.previous_state.leave to true for 1 frame and self.state.previous_state.active to false, where "previous_state" would be the name of the previously active state.
-- The state changes happen at the end of this frame, and are valid for the next frame. So no matter from where you call "go" from, the state transitions will be valid for the next frame only.
-- "game:go('default')" is automatically called for the main "game" object, which allows you to easily work with it in the update function:
--[[
  function update(dt)
    if game.states.default.enter then
      -- initialize game objects, containers, etc
    end
    -- update everything
  end
]]--
function state:go(state)
  self.state_change_for_next_frame = state
end

function state:state_post_update(dt)
  for k, v in pairs(self.states) do
    if v.enter ~= game.step then v.enter = false end
    if v.leave ~= game.step then v.leave = false end
  end

  if self.state_change_for_next_frame then
    for k, v in pairs(self.states) do
      if v.active then v.leave = game.step end
      v.active = false
    end
    self.states[self.state_change_for_next_frame].enter = game.step
    self.states[self.state_change_for_next_frame].active = true
    self.state_change_for_next_frame = nil
  end
end
