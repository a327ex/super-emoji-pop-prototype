-- https://github.com/1bardesign/batteries/blob/master/measure.lua
measure = {}
measure.get_time = os.time
if love and love.timer then measure.get_time = love.timer.getTime end


function measure.time_taken(test_function, runs, warmup_runs)
  runs = runs or 1000
  warmup_runs = warmup_runs or 0
  local times = {}
  for i = 1, warmup_runs + runs do
    local start_time = measure.get_time()
    test_function()
    local end_time = measure.get_time()
    if i > warmup_runs then
      table.insert(times, end_time - start_time)
    end
  end
  local mean = table.mean(times)
  local min, max = table.minmax(times)
  return mean, min, max
end


function measure.memory_taken(test_function, runs, warmup_runs)
  runs = runs or 1000
  warmup_runs = warmup_runs or 0
  local mems = {}
  for i = 1, warmup_runs + runs do
    local start_mem = collectgarbage('count')
    test_function()
    local end_mem = collectgarbage('count')
    if i > warmup_runs then
      table.insert(mems, math.max(0, end_mem - start_mem))
    end
  end
  local mean = table.mean(mems)
  local min, max = table.minmax(mems)
  return mean, min, max
end


function measure.memory_taken_strict(test_function, runs, warmup_runs)
  runs = runs or 1000
  warmup_runs = warmup_runs or 0
  local mems = {}
  for i = 1, warmup_runs + runs do
    collectgarbage('collect')
    collectgarbage('stop')
    local start_mem = collectgarbage('count')
    test_function()
    local end_mem = collectgarbage('count')
    if i > warmup_runs then
      table.insert(mems, math.max(0, end_mem - start_mem))
    end
  end
  collectgarbage('restart')
  local mean = table.mean(mems)
  local min, max = table.minmax(mems)
  return mean, min, max
end
