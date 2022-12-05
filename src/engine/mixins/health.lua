health = class:use()
function health:health(hp)
  self.max_hp = hp or 1
  self.hp = self.max_hp
end

function health:hurt(amount)
  self.hp = self.hp - (amount or 0)
  if self.hp <= 0 then
    self.hp = 0
    return true
  end
end

function health:heal(amount)
  self.hp = self.hp + (amount or 0)
  if self.hp >= self.max_hp then
    self.hp = self.max_hp
    return true
  end
end
