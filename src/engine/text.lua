-- Adds generic character based text to the game object.
-- This implements a character based tagging system which should allow you to implement any kind of text effect possible, from setting a character's color to making it become visible, shake and play sounds.
--[[
  text_tag_1 = function(dt, text, c)
    set_color(colors.yellow[0])
  end
  text_tag_2 = function(dt, text, c)
    c.ox = random:float(-2, 2) 
    c.oy = random:float(-2, 2)
  end
  text_object = make(
    pos(g.w/2, g.h/2),
    text(
      '[this text is yellow](yellow), [this text is shaking](shaking), [this text is yellow and shaking](yellow, shaking), this text is normal',
    }, {font = some_font, w = 200, alignment = 'left', height_multiplier = 1.5, text_tags = {yellow = text_tag_1, shaking = text_tag_2}}),
  )
-- There are two main things happening in the example above: first we're creating text_tags and then we're creating a text object that uses those tags.
-- The way each tag works is fairly simple: a text tag is an update function that operates on the text's characters one at a time.
-- In the example above, the text without tags is 'this text is yellow, this text is shaking, this text is yellow and shaking, this text is normal'.
-- For each of the characters in that string, different functions will be applied based on what tags were previously applied to it.
-- The tag's update function always takes 3 arguments:
--   text - the text object
--   dt - delta passed from above update function
--   character - the current character, which is a table containing .x, .y, .r, .sx, .sy, .ox, .oy, .c, .line, .i and .tags attributes
-- The tag function for each character will be called every frame. To do something only in the first frame of the text's existence for a given tag, use "if self.text_init then" in the tag function.
-- After we're done creating the text tags, we have to create the actual text object.
-- The way this is done is by creating a normal game object using the text mixin, which lets you pass in two arguments: the text string and an optional text formatting table.
-- The arguments for this formatting table can be the following:
  -- font - the font to be used for the text, if not specified will use the engine's default font
  -- text_tags - the tags to be used for the text, if not specified will use the engine's globally defined text tags (text_tags)
  -- alignment - how the text should align itself, possible values are 'center', 'justified', 'right', if not specified then by default it's 'left'
  -- wrap_width - automatically wraps the text to the next line when the text reaches this width
  -- height_multiplier - multiplier over the font's height for placing the line below
-- The text object itself also has .w and .h attributes which correspond to the width of the full text (or the wrap width, if defined) and the height of all lines put together.
]]--
text = class:use()
function text:new(text, opts)
  local opts = opts or {}
  self.font = opts.font or fonts.lana
  self.text_tags = opts.tags or text_tags or {}
  self.alignment = opts.alignment or 'left'
  self.wrap_width = opts.wrap_width or 1000000
  self.height_multiplier = opts.height_multiplier or 1
  self.raw_text = text
  self.text_init = true
  self:parse_and_format_text()
end

-- Parses the text and applies formatting to each character.
-- This adds the attributes .c, .x, .y, .r, .sx, .sy, .ox, .oy, .line, .i, .tags to each character.
-- All of these values are applied locally, i.e. .x, .y is the character's local position.
-- The character's final position will be the object's .x + the character's .x (+ the character's .ox offset).
function text:parse_and_format_text()
  local font = self.font
  local tags = self.text_tags
  local alignment = self.alignment
  local wrap_width = self.wrap_width
  local height_multiplier = self.height_multiplier

  -- Parse tagged substrings and the tags themselves
  local tagged_text = {}
  for i, field, j, tags, k in utf8.gmatch(self.raw_text, "()%[(.-)%]()%((.-)%)()") do
    local tags_table = {}
    for tag in utf8.gmatch(tags, "[%w_]+") do table.insert(tags_table, tag) end
    table.insert(tagged_text, {i = tonumber(i), j = tonumber(j), k = tonumber(k), field = field, tags = tags_table})
    -- i to j-1 is [field]
    -- i+1 to j-2 is field
    -- j to k-1 is (tag)
    -- j+1 to k-2 is tag
  end

  -- Create the characters table, which holds each of the text's characters along with the tags that apply to each of them
  local characters = {}
  for i = 1, utf8.len(self.raw_text) do
    local c = utf8.sub(self.raw_text, i, i)
    if c ~= '[' and c ~= ']' and c ~= '(' and c ~= ')' then
      local tags = nil
      local should_be_character = true
      for _, t in ipairs(tagged_text) do
        if i >= t.i and i <= t.j-1 then
          tags = t.tags
        end
        if i >= t.j and i <= t.k-1 then
          should_be_character = false
        end
      end
      if should_be_character then
        table.insert(characters, {c = c, tags = tags or {}})
      end
    end
  end

  -- Set .x, .y, .r, .sx, .sy, .ox, .oy and .line for each character
  local current_x, current_y = 0, 0
  local current_line = 1
  for i, c in ipairs(characters) do
    if c.c == '|' then
      current_x = 0
      current_y = current_y + font.h*height_multiplier
      current_line = current_line + 1
    elseif c.c == ' ' then
      local wrapped = false
      if #c.tags <= 1 then -- only check for wrapping if this space is not inside tag delimiters ()
        local from_space_x = current_x
        for j = i+1, (table.find(table.get(characters, i+1, -1), function(v) return v.c == ' ' end) or 0) + i do -- go from next character to next space (the next word) to see if it fits this line
          from_space_x = from_space_x + font:get_text_width(characters[j].c)
        end
        if from_space_x > wrap_width then -- if the word doesn't fit then wrap line here
          current_x = 0
          current_y = current_y + font.h*height_multiplier
          current_line = current_line + 1
          wrapped = true
        end
      end
      if not wrapped then
        c.x, c.y = current_x, current_y
        c.line = current_line
        c.r = 0
        c.sx, c.sy = 1, 1
        c.ox, c.oy = 0, 0
        current_x = current_x + font:get_text_width(c.c)
        if current_x > wrap_width then
          current_x = 0
          current_y = current_y + font.h*height_multiplier
          current_line = current_line + 1
        end
      else
        c.c = '|' -- set to | to remove it in the next step, as it was already wrapped and doesn't need to be visually represented
      end
    else
      c.x, c.y = current_x, current_y
      c.line = current_line
      c.r = 0
      c.sx, c.sy = 1, 1
      c.ox, c.oy = 0, 0
      current_x = current_x + font:get_text_width(c.c)
      if current_x > wrap_width then
        current_x = 0
        current_y = current_y + font.h*height_multiplier
        current_line = current_line + 1
      end
    end
  end

  -- Removes line separators as they're not needed anymore
  for i = #characters, 1, -1 do
    if characters[i].c == '|' then
      table.remove(characters, i)
    end
  end

  -- Set .i for each character
  for i, c in ipairs(characters) do
    c.i = i
  end

  -- Figure out .w and .h and also the width of each line to set alignment next
  local text_w = 0
  local line_widths = {}
  for i = 1, characters[#characters].line do
    local line_w = 0
    for j, c in ipairs(characters) do
      if c.line == i then
        line_w = line_w + font:get_text_width(c.c)
      end
    end
    line_widths[i] = line_w
    if line_w > text_w then
      text_w = line_w
    end
  end
  local text_h = characters[#characters].y + font.h*height_multiplier

  -- Sets the position of each character to match the given .alignment, unchanged if it is 'left'
  for i = 1, characters[#characters].line do
    local line_w = line_widths[i]
    local leftover_w = text_w - line_w
    if alignment == 'center' then
      for _, c in ipairs(characters) do
        if c.line == i then
          c.x = c.x + leftover_w/2
        end
      end
    elseif alignment == 'right' then
      for _, c in ipairs(characters) do
        if c.line == i then
          c.x = c.x + leftover_w
        end
      end
    elseif alignment == 'justify' then
      local spaces_count = 0
      for _, c in ipairs(characters) do
        if c.line == i then
          if c.c == ' ' then
            spaces_count = spaces_count + 1
          end
        end
      end
      local added_width_to_each_space = math.floor(leftover_w/spaces_count)
      local total_added_width = 0
      for _, c in ipairs(characters) do
        if c.line == i then
          if c.c == ' ' then
            c.x = c.x + added_width_to_each_space
            total_added_width = total_added_width + added_width_to_each_space
          else
            c.x = c.x + total_added_width
          end
        end
      end
    end
  end

  self.characters = characters
  self.w = text_w
  self.h = text_h
end

function text:set_text(text)
  self.raw_text = text
  self:parse_and_format_text()
end

function text:update(layer, dt, x, y, r, sx, sy, ox, oy, z, fixed)
  push(layer, x or self.x, y or self.y, r or self.r or 0, sx or self.sx or 1, sy or self.sy or sx or self.sx or 1, z, fixed)
    for _, c in ipairs(self.characters) do
      for _, character_tag in ipairs(c.tags) do
        for tag_name, text_tag in pairs(self.text_tags) do
          if tag_name == character_tag then
            if type(text_tag) == 'function' then
              text_tag(layer, dt, self, c, z, fixed)
            end
          end
        end
      end
      print_text(layer, c.c, self.font, (x or self.x) + c.x - self.w/2 - (ox or 0), (y or self.y) + c.y - self.h/2 - (oy or 0), c.r or 0, c.sx or 1, c.sy or c.sx or 1, c.ox or 0, c.oy or 0, z, fixed)
      set_color(layer, colors.fg[0], z, fixed)
    end
  pop(layer, z, fixed)
  self.text_init = false
end
