-- https://github.com/1bardesign/batteries/blob/master/manual_gc.lua
function manual_gc(time_budget, memory_ceiling, disable_otherwise)
  time_budget = time_budget or 1e-3
  memory_ceiling = memory_ceiling or 64
  local max_steps = 1000
  local steps = 0
  local start_time = love.timer.getTime()

  while love.timer.getTime() - start_time < time_budget and steps < max_steps do
    collectgarbage('step', 1)
    steps = steps + 1
  end

  if collectgarbage('count')/1024 > memory_ceiling then
    collectgarbage('collect')
  end
  if disable_otherwise then
    collectgarbage('stop')
  end
end
