system = {}
function system.update(dt)
  if input.f12.pressed then
    for k, v in pairs(system.type_count()) do print(k, v) end
    collectgarbage("collect")
    print(math.round(tonumber(collectgarbage("count"))/1024, 5) .. "MB")
  end
end

global_type_table = nil
function system.type_name(o)
  if global_type_table == nil then
    global_type_table = {}
    for k, v in pairs(_G) do
      global_type_table[v] = k
    end
    global_type_table[0] = "table"
  end
  return global_type_table[getmetatable(o) or 0] or "Unknown"
end

function system.count_all(f)
  local seen = {}
  local count_table
  count_table = function(t)
    if seen[t] then return end
    f(t)
    seen[t] = true
    for k, v in pairs(t) do
      if type(v) == "table" then count_table(v)
      elseif type(v) == "userdata" then f(v)
      end
    end
  end
  count_table(_G)
end

function system.type_count()
  local counts = {}
  local enumerate = function(o)
    if type(o) == 'function' then
      local upvalues = {}

    else
      local t = system.type_name(o)
      counts[t] = (counts[t] or 0) + 1
    end
  end
  system.count_all(enumerate)
  return counts
end

function system.enumerate_files(path, filter)
  local function recursive_enumerate(path, files)
    local items = love.filesystem.getDirectoryItems(path)
    for _, item in ipairs(items) do
      local file = path .. "/" .. item
      local info = love.filesystem.getInfo(file)
      if info.type == "file" then
        table.insert(files, file)
      elseif info.type == "directory" then
        recursive_enumerate(file, files)
      end
    end
  end

  local files = {}
  recursive_enumerate(path, files)
  if filter then
    local filtered_files = {}
    for _, file in ipairs(files) do
      if file:find(filter) then
        table.insert(filtered_files, file:left(filter):right(path .. "/"))
      end
    end
    return filtered_files
  else
    return files
  end
end

function system.set_identity(name)
  love.filesystem.setIdentity(name)
end

function system.does_file_exist(path)
   local file = io.open(path, "r")
   if file then
      file:close()
      return true
   end
end

function system.load_files(path, filter, exclude_table)
  local exclude_table = {unpack(exclude_table or {})}
  for _, file in ipairs(system.enumerate_files(path, filter)) do
    if not table.contains(exclude_table, file) then
      require(path .. "." .. file)
    end
  end
end

function system.save_file(filename, data)
  love.filesystem.write(filename, 'return ' .. table.tostring(data))
end

function system.load_file(filename)
  local chunk = love.filesystem.load(filename)
  if chunk then return chunk() end
end

function system.save_table(filename, t)
  love.filesystem.createDirectory("")
  local str = "return " .. table.tostring(t or {})
  love.filesystem.write(filename, str)
end

function system.get_main_directory()
  return love.filesystem.getSource()
end

function system.get_save_directory()
  return love.filesystem.getSaveDirectory()
end

function system.rename(old_path, new_path)
  os.rename(old_path, new_path)
end

function system.execute(cmd)
  os.execute(cmd)
end

function system.remove(path)
  os.remove(path)
end

function system.open_url(url)
  love.system.openURL(url)
end
