-- Creates a new mixin that can then be called with "make" to create new game objects.
-- pos = mixin() creates the pos table as a mixin and then game_object = make(pos(10, 10)) creates a game object with the pos mixin in it.
-- The pos() call simply creates a mixin object that has the .args table set to the arguments passed in via the make call.
-- The make call then takes those arguments and properly initializes the mixin inside the game object as it creates it.
-- All functions defined by the mixin are copied to every game object, all attributes passed in are also copied based on the mixin's "init" function.
-- For instance: "function pos:init(x, y) self.x, self.y = x, y end" will initialize the game object's .x and .y attributes to the values passed in to the pos mixin in a make call.
function mixin()
  local new_mixin = class:use()
  function new_mixin:new(...)
    self.args = {...}
  end
  return new_mixin
end


-- Creates a new game object based on the mixins, game objects, or tables passed in.
-- Every game object, other than the ones in the engine/modules folder, should be created this way.
-- If mixins are passed in:
--   What this function does is simply copy all the function references defined by each mixin into the new game object.
--   Attributes defined in each mixin's "init" function are also copied.
-- If game objects are passed in:
--   Every game object needs to have a "name" mixin and a unique name among other game objects that make up the composed game object.
--   For instance, "composed_object = make(make(name('object_1')), make(name('object_2')))", will create a new object composed of objects named "object_1" and "object_2".
--   Each object can be accessed from the composed object via their names, so, composed_object.object_1 and composed_object.object_2 in this example.
--   Each object also has a reference to each other object in the composition. So object_1 has a reference to object_2 and vice versa. They also reference the composed object via the .parent attribute.
--   Because all references are name based, these names need to be unique across all other objects in the composition as well as all possible fields.
--   Naming an object "x", for instance, would be a bad idea, since most other objects will already have the "x" field representing its position.
-- If normal tables are passed in:
--   All keys and values from the table are copied to the created game object.
-- An example:
--   object = make(
--     pos(0, 0),
--     make(name('object_1')),
--     make(name('object_2')),
--     {attribute_1 = 1, attribute_2 = true}
--   )
-- The above example will create an object with the following structure:
--   object = {
--     x = 0, y = 0,
--     move = ...,
--     move_to = ...,
--     get_screen_pos = ...,
--     object_1 = ...,
--     object_2 = ...,
--     attribute_1 = 1,
--     attribute_2 = true
--   }
-- The object will take all attributes and functions defined from each mixin passed in (in this case "pos");
-- will create attributes with the name of any objects passed in (in this case object_1 and object_2), if the objects don't have the "name" mixin then an error will happen;
-- and will create attributes with the keys and values of any tables passed in.
-- Objects passed in will all point to each other (object_1.object_2 and object_2.object_1 in this example), as well as to the object that contains them via the .parent attribute.
local is = function(self, mixin)
  if type(mixin) == 'string' then return self.__tags[mixin]
  else return self.__mixins[mixin] end
end
local requires = function(self, ...) for _, mixin in ipairs({...}) do if self:is(mixin) then return true end end; error ('required mixins not in object') end
local forbids = function(self, ...) for _, mixin in ipairs({...}) do if self:is(mixin) then error('forbidden mixin "' .. mixin.__class .. '" in object') end end return true end
function make(...)
  local new_game_object = {
    __mixins = {},
    __tags = {},
    id = random and random:uid() or 0,
    is = is,
    requires = requires,
    forbids = forbids
  }

  local elements = {...}
  local objects = {}
  local attributes_to_be_merged = {}
  for _, element in ipairs(elements) do
    if type(element) == 'string' then -- it's a tag, add it to the tags list
      new_game_object.__tags[element] = true
    elseif element.__class then -- it's a mixin, copy all function references
      for k, v in pairs(element.__class) do
        if type(v) == 'function' then
          if k ~= 'new' and k ~= 'init' then
            if new_game_object[k] and type(new_game_object[k]) == 'function' then
              local old_function = new_game_object[k]
              new_game_object[k] = function(self, ...) -- if a function with this name already exists, create a new function that calls the old one with the new one appended to its end
                old_function(self, ...)
                v(self, ...)
              end
            else
              new_game_object[k] = v
            end
          end
        end
        new_game_object.__mixins[element.__class] = true
      end
    elseif element.__mixins then -- it's an object, simply check if it has name mixin, set .parent for each object and the object's name on new_game_object
      if not element:is(name) then
        error('all composed objects must have the "name" mixin')
      end
      element.parent = new_game_object
      new_game_object[element.name] = element
      table.insert(objects, element)
    else -- isn't a mixin nor an object, just a table with attributes that need to be added directly to the object
      for k, v in pairs(element) do
        attributes_to_be_merged[k] = v
      end
    end
  end

  -- initialize the mixin's init function, adding attributes defined there to new_game_object
  for _, element in ipairs(elements) do
    if element.__class then
      element.init(new_game_object, unpack(element.args))
    end
  end

  -- point every object to every other object
  for _, a in ipairs(objects) do 
    for _, b in ipairs(objects) do
      if a.__mixins and b.__mixins and a.id ~= b.id then
        if not a[b.name] then
          a[b.name] = b
        else
          error('name collision on "' .. b.name .. '" attribute when composing objects, all object names must be unique across objects and across object attributes')
        end
      end
    end
  end

  -- merge attributes from normal lua tables
  for k, v in pairs(attributes_to_be_merged) do new_game_object[k] = v end

  if new_game_object:is(area) then area_objects:add(new_game_object) end
  if new_game_object:is(stats) then stats_objects:add(new_game_object) end
  if new_game_object:is(state) then 
    if not new_game_object:is(window) then -- don't add "game" to the states container, as the container hasn't been created when "game" is being created through here, resulting in nil access
      state_objects:add(new_game_object)
    end
  end

  return new_game_object
end
