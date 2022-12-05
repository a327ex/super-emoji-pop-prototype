screen = class:use(state, timer)
function screen:new(args)
  args = args or {}
  self.name = args.name or 'default'
  love.filesystem.setIdentity(self.name)
  self.w, self.h = args.w or 480, args.h or 270
  self.smooth = args.smooth

  local settings = table.load('settings.txt')
  if not settings or args.reset_settings then
    self.is_first_run = true
    settings = {}
  end

  -- These settings are saved to the settings.txt file, this file shouldn't be uploaded to things like Steam Cloud, since we don't want window and a few other settings to be saved across devices.
  self.sx, self.sy = settings.sx or 1, settings.sy or 1
  self.display = settings.display or 1
  self.desktop_w, self.desktop_h = love.window.getDesktopDimensions(self.display)
  self.window_w, self.window_h = settings.window_w or self.desktop_w, settings.window_h or self.desktop_h
  self.main_canvas_leftover_w, self.main_canvas_leftover_h = settings.main_canvas_leftover_w, settings.main_canvas_leftover_h
  self.fullscreen = settings.fullscreen or 'yes' -- values can be 'yes' or 'no'
  self.scale = settings.scale or 'fit' -- values can be 'fit', 'stretch', or an integer that represents the scale
  self.max_scale = settings.max_scale -- maximum integer value that the scaling mode can reach

  if self.is_first_run then self:set_fullscreen_and_scale('yes', 'fit')
  else self:set_fullscreen_and_scale(self.fullscreen, self.scale) end
  self:set_window()

  if self.smooth then
    love.graphics.setLineStyle('smooth')
    love.graphics.setDefaultFilter('linear', 'linear', 8)
  else
    love.graphics.setLineStyle('rough')
    love.graphics.setDefaultFilter('nearest', 'nearest', 0)
  end

  self.framerate = nil
  self.rate = 1/60
  self.timescale = 1
  self.sleep = .001
  self.accumulator = 0
  self.step = 1
  self.frame = 1
  self.time = 0

  self:set_theme(args.theme)
  self:state()
  self:timer()
end

function screen:set_fullscreen_and_scale(fullscreen, scale)
  if fullscreen == 'yes' and scale == 'fit' then
    self.fullscreen = 'yes'
    self.scale = 'fit'
    local scale_to_fit_width, scale_to_fit_height = self.desktop_w/self.w, self.desktop_h/self.h
    local scale = math.min(scale_to_fit_width, scale_to_fit_height)
    self.sx, self.sy = scale, scale
    self.window_w, self.window_h = self.desktop_w, self.desktop_h
    self.main_canvas_leftover_w, self.main_canvas_leftover_h = self.window_w - self.w*self.sx, self.window_h - self.h*self.sy
    self.max_scale = math.floor(scale)
  elseif fullscreen == 'yes' and scale == 'stretch' then
    self.fullscreen = 'yes'
    self.scale = 'stretch'
    self.sx, self.sy = self.desktop_w/self.w, self.desktop_h/self.h
    self.window_w, self.window_h = self.desktop_w, self.desktop_h
    self.main_canvas_leftover_w, self.main_canvas_leftover_h = 0, 0
    self.max_scale = math.floor(math.min(self.sx, self.sy))
  elseif fullscreen == 'yes' and type(scale) == 'number' then
    self.fullscreen = 'yes'
    self.scale = scale
    self.sx, self.sy = scale, scale
    self.window_w, self.window_h = self.desktop_w, self.desktop_h
    self.main_canvas_leftover_w, self.main_canvas_leftover_h = self.window_w - self.w*self.sx, self.window_h - self.h*self.sy
    self.max_scale = scale
  elseif fullscreen == 'no' and (type(scale) == 'number' or scale == 'max') then
    self.fullscreen = 'no'
    self.max_scale = math.min(self.desktop_w/self.w, self.desktop_h/self.h) - 1
    self.scale = scale == 'max' and self.max_scale or scale
    self.sx, self.sy = self.scale, self.scale
    self.window_w, self.window_h = self.w*self.sx, self.h*self.sy
    self.main_canvas_leftover_w, self.main_canvas_leftover_h = 0, 0
  end
end

function screen:set_window()
  love.window.setMode(self.window_w, self.window_h, {msaa = self.smooth and 8 or 0, display = self.display})
  love.window.setIcon(love.image.newImageData('assets/images/icon.png'))
  love.window.setTitle(self.name)
end

function screen:set_theme(theme)
  self.theme = theme or 'snkrx'
  if self.theme == 'snkrx' then
    self.colors = {
      white = color_ramp(color(1, 1, 1, 1), 0.025),
      black = color_ramp(color(0, 0, 0, 1), 0.025),
      gray = color_ramp(color(0.5, 0.5, 0.5, 1), 0.025),
      bg = color_ramp(color(48, 48, 48), 0.025),
      fg = color_ramp(color(218, 218, 218), 0.025),
      yellow = color_ramp(color(250, 207, 0), 0.025),
      orange = color_ramp(color(240, 112, 33), 0.025),
      blue = color_ramp(color(1, 155, 214), 0.025),
      green = color_ramp(color(139, 191, 64), 0.025),
      red = color_ramp(color(233, 29, 57), 0.025),
      purple = color_ramp(color(142, 85, 158), 0.025),
    }
  elseif self.theme == 'bytepath' then -- https://coolors.co/191516-f5efed-52b3cb-b26ca1-79b159-ffb833-f4903e-d84654
    self.colors = {
      white = color_ramp(color(1, 1, 1, 1), 0.025),
      black = color_ramp(color(0, 0, 0, 1), 0.025),
      gray = color_ramp(color(0.5, 0.5, 0.5, 1), 0.025),
      bg = color_ramp(color('#111111'), 0.025),
      fg = color_ramp(color('#dedede'), 0.025),
      yellow = color_ramp(color('#ffb833'), 0.025),
      orange = color_ramp(color('#f4903e'), 0.025),
      blue = color_ramp(color('#52b3cb'), 0.025),
      green = color_ramp(color('#79b159'), 0.025),
      red = color_ramp(color('#d84654'), 0.025),
      purple = color_ramp(color('#b26ca1'), 0.025),
    }
  elseif self.theme == 'twitter_emoji' then -- colors taken from twitter emoji set
    self.colors = {
      white = color_ramp(color(1, 1, 1, 1), 0.025),
      black = color_ramp(color(0, 0, 0, 1), 0.025),
      gray = color_ramp(color(0.5, 0.5, 0.5, 1), 0.025),
      bg = color_ramp(color(41, 49, 55), 0.025),
      fg = color_ramp(color(231, 232, 233), 0.025),
      yellow = color_ramp(color(253, 205, 86), 0.025),
      orange = color_ramp(color(244, 146, 0), 0.025),
      blue = color_ramp(color(83, 175, 239), 0.025),
      green = color_ramp(color(122, 179, 87), 0.025),
      red = color_ramp(color(223, 37, 64), 0.025),
      purple = color_ramp(color(172, 144, 216), 0.025),
      brown = color_ramp(color(195, 105, 77), 0.025),
    }
  elseif self.theme == 'google_noto' then -- colors taken from google noto emoji set
    self.colors = {
      white = color_ramp(color(1, 1, 1, 1), 0.025),
      black = color_ramp(color(0, 0, 0, 1), 0.025),
      gray = color_ramp(color(0.5, 0.5, 0.5, 1), 0.025),
      bg = color_ramp(color(66, 66, 66), 0.025),
      fg = color_ramp(color(224, 224, 224), 0.025),
      yellow = color_ramp(color(255, 205, 46), 0.025),
      orange = color_ramp(color(255, 133, 0), 0.025),
      blue = color_ramp(color(18, 119, 211), 0.025),
      green = color_ramp(color(125, 180, 64), 0.025),
      red = color_ramp(color(244, 65, 51), 0.025),
      purple = color_ramp(color(172, 69, 189), 0.025),
      brown = color_ramp(color(184, 109, 83), 0.025),
    }
  else
    error('theme name "' .. self.theme .. '" does not exist')
  end

  for color_name, c in pairs(self.colors) do
    if not color_name:find('_transparent') then
      self.colors[color_name .. '_transparent'] = color(c[0].r, c[0].g, c[0].b, 0.5)
      self.colors[color_name .. '_transparent_weak'] = color(c[0].r, c[0].g, c[0].b, 0.25)
    end
  end
  self.colors.shadow = color(0.1, 0.1, 0.1, 0.4)
  self.colors.modal_transparent = color(0.1, 0.1, 0.1, 0.9)
  self.colors.modal_transparent_weak = color(0.1, 0.1, 0.1, 0.6)
  self.colors.bg_off = {}
  for i = 1, 4 do self.colors.bg_off[i] = color(self.colors.bg[0].r - (1 + i)/255, self.colors.bg[0].g - (1 + i)/255, self.colors.bg[0].b - (1 + i)/255) end

  love.graphics.setBackgroundColor(unpack(self.colors.bg[0]:to_table()))
  love.graphics.setColor(unpack(self.colors.fg[0]:to_table()))
end

function screen:slow(amount, duration)
  self.timescale = amount
  self:tween(duration, self, {timescale = 1}, math.cubic_in_out, function() self.timescale = 1 end, 'slow')
end
