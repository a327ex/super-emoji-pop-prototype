font = class:use()
function font:new(font_name, font_size)
  self.font = love.graphics.newFont('assets/fonts/' .. font_name, font_size)
  self.h = self.font:getHeight()
end

function font:get_text_width(text)
  return self.font:getWidth(text)
end

function load_fonts()
  fonts = {}
  fonts.lana = font('LanaPixel.ttf', 11)
  fonts.pixul = font('PixulBrush.ttf', 8)
  fonts.fat = font('FatPixelFont.ttf', 8)
  fonts.ark = font('ark.ttf', 12)
  fonts.fusion = font('fusion-pixel.ttf', 12)
end
