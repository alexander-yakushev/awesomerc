local format = string.format
local gsub = string.gsub

local util = {}

function util.pango(text, args, escape_brackets)
   local font = args.font
   local foreground = args.foreground
   local weight = args.weight
   local letter_spacing = args.letter_spacing
   local result = '<span'

   if escape_brackets then
      text = gsub(gsub(gsub(text,
                            "&", "&amp;"),
                       "<", "&lt;"),
                  ">", "&gt;")
   end

   if font then
      result = result .. format(' font = "%s"', font)
   end
   if foreground then
      result = result .. format(' foreground = "%s"', foreground)
   end
   if weight then
      result = result .. format(' weight = "%s"', weight)
   end
   if letter_spacing then
      result = result .. format(' letter-spacing = "%s"', letter_spacing)
   end
   return format(result .. '>%s</span>', text)
end

function util.color_to_r_g_b_a(color)
   if type(color) == "string" and string.sub(color, 1, 1) == "#" then
      local r = tonumber(string.sub(color, 2, 3), 16) / 256
      local g = tonumber(string.sub(color, 4, 5), 16) / 256
      local b = tonumber(string.sub(color, 6, 7), 16) / 256
      local a = tonumber(string.sub(color, 8, 9), 16) / 256
      return r, g, b, a
   elseif type(color) == "table" then
      return color[1], color[2], color[3], color[4]
   else
      error("E: util.color_to_r_g_b_a: unknown color format")
   end
end

return util
