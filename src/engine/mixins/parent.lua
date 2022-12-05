parent = class:use()
function parent:parent_init(parent, die_on_parent_death)
  self.parent = parent
  self.die_on_parent_death = die_on_parent_death
end

function parent:parent_update(dt)
  if self.die_on_parent_death then
    if self.parent.dead then
      self.dead = true
      return true
    end
  end
end
