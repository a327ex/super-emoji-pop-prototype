-- A mixin that handles stats capabilities
-- A simple example:
--   self:set_stat('str', 0, -10, 10)
--   self:set_stat('con', 0, -10, 10)
--   self:set_stat('dex', 0, -10, 10)
--   self:set_stat('int', 0, -10, 10)
-- self.stat.str, self.stat.con, self.stat.dex and self.stat.int are now a table with attributes .x = 0, .min = -10 and max = 10.
-- If you want to add to the original stat:
--   self:add_to_stat('str', 10)
-- This will make self.stats.str.x = 10. If you want to decrease it:
--   self:add_to_stat(self.stats, 'str', -10)
-- Now self.stats.str.x is 0. If you try to increase or decrease the value beyond its limits then it will be capped:
--   self:add_to_stat(self.stats, 'str', 1000)
-- self.stats.str.x is now 10, which is the maximum value it can have.
-- Often times in games you don't want permanent additions, but temporary ones due to buffs. To achieve this use stats_set_adds and stats_set_mults every frame:
--   self:set_stat_adds('str', self.str_buff_1 and 1 or 0, self.str_buff_2 and 1 or 0, self.str_buff_3 and 2 or 0, self.str_buff_4 and 4 or 0)
--   self:set_stat_mults('str', self.str_buff_5 and 0.2 or 0, self.str_debuff_1 and -0.2 or 0, self.str_buff_6 and 0.5 or 0)
-- And in this case self.stats.str will have buffs that add up to 8 (meaning if the base str value is 10 then it will be 18 as long as all the buffs are up),
-- and it will also have its buffs multiplied by the addition of all mults, in this case they all add up to 0.5, so the final value str value will be (base + adds)*(1 + mults),
-- which, assuming base str is 2, will end up being (2 + 8)*1.5 = 15, but because the max for str is 10 then it will just be 10.
-- It's important to note that self:set_stat_adds and self:set_stat_mults have to be called every frame with the appropriate modifiers set,
-- as additions and multipliers set through these functions are temporary and assumed to be non-existant if the functions aren't called.
stats = class:use()
function stats:stats()
  self.stat = {}
end

-- Updates all stats that have been registered with self:setstats
-- Call this after using self:set_adds or self:set_mults for this frame
function stats:stats_update(dt)
  for stat_name, stat in pairs(self.stat) do
    local adds, mults = 0, 1
    for _, add in ipairs(stat.adds or {}) do adds = adds + add end
    for _, mult in ipairs(stat.mults or {}) do mults = mults + mult end
    stat.x = math.clamp((stat.x + adds)*mults, stat.min, stat.max)
  end
end

-- Resets all adds and mults for every stat
-- Automatically called for every object that has the stat mixin at the end of the frame
function stats:stats_post_update(dt)
  for stat_name, stat in pairs(self.stat) do
    stat.adds = nil
    stat.mults = nil
  end
end

-- Registers a stat of the given name and with the given value and limits.
-- self:set_stat('hp', 10, 0, 20)
-- Now self.stat.hp.x is 10, and its minimum and maximum values are 0 and 20 respectively.
function stats:set_stat(name, x, min, max)
  self.stat[name] = {x = x, min = min or -1000000, max = max or 1000000}
end

-- Adds a value to the stat of the given name.
-- self:add_to_stat('hp', 5)
-- If self.stat.hp.x was 10, now it will be 15. The stats' value will be clamped to its limits.
function stats:add_to_stat(name, v)
  self.stat[name].x = self.stats[name].x + v
  self.stat[name].x = math.clamp(self.stat[name].x, self.stat[name].min, self.stat[name].max)
end

-- Sets additive values to the given stat for this frame.
-- self:set_stat_adds('str', self.str_buff_1 and 2 or 0, self.str_buff_2 and 4 or 0)
-- This will add 6 to self.stat.str whenever both self.str_buff_1 and self.str_buff_2 are true.
function stats:set_stat_adds(name, ...)
  self.stat[name].adds = {...}
end

-- Sets multiplicative values to the given stat for this frame. Multiplicatives are added together and then multiply the base value and the added values.
-- self:set_stat_mults('str', self.str_buff_3 and 0.2 or 0, self.str_buff_4 and 0.6 or 0)
-- This will multiply the base + added values by 1.8 whenever both self.str_buff_3 and self.str_buff_4 are true.
function stats:set_stat_mults(name, ...)
  self.stat[name].mults = {...}
end
