sound = class:use()
function sound:new(asset_name, args)
  for k, v in ipairs(args or {}) do self[k] = v end
  local info = love.filesystem.getInfo('assets/sounds/' .. asset_name .. '.ogg')
  self.source = love.audio.newSource('assets/sounds/' .. asset_name .. '.ogg', (info and info.size and info.size < 5e5) and 'static' or 'stream')
  self.instances = {}
  table.insert(sounds, self)
end

-- Cleans up stopped instances.
function sound:update(dt)
  for i = #self.instances, 1, -1 do
    if not self.instances[i]:isPlaying() then
      table.remove(self.instances, i)
    end
  end
end

-- Plays a sound. If the sound is not loaded then load it. Big files are automatically loaded as 'stream'.
-- sound:play(0.5, random:float(0.9, 1.1)) -> returns the instance being played
function sound:play(volume, pitch)
  local instance = self.source:clone()
  instance:setVolume((volume or 1)*(self.tag and self.tag.volume or 1))
  instance:setPitch(pitch or 1)
  instance:play()
  table.insert(self.instances, instance)
  return instance
end


-- Creates a new tag that can be used to affect sounds collectively.
-- sfx = sound_tag{volume = 0.5})
-- s = sound(..., {tag = sfx})
sound_tag = class:use()
function sound_tag:new(args)
  self.volume = args and args.volume or 1
  self.effects = args and args.effects
end


function load_sounds()
  sounds = {}
  sfx, music = sound_tag{volume = 0.5}, sound_tag{volume = 0.5}
  for _, file in ipairs(system.enumerate_files('assets/sounds', '.ogg')) do
    sounds[file] = sound(file)
    if file:find('music') then sounds[file].tag = music
    else sounds[file].tag = sfx end
  end
end
