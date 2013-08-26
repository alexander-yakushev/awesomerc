---------------------------------------------------------------------------
-- @author Antonio Terceiro
-- @copyright 2009, 2011-2012 Antonio Terceiro, Alexander Yakushev
-- @release @AWESOME_VERSION@
---------------------------------------------------------------------------

local util = require("awful.util")
local theme = require("beautiful")

-- Module iconic
local iconic = {}

-- NOTE: This icons module was written according to the following
-- freedesktop.org specification:
-- http://standards.freedesktop.org/icon-theme-spec/icon-theme-spec-0.11.html

-- Options section

-- Default icon to be used when no icon was found.
local default_icon = nil

-- Private section

local all_icon_sizes = {
   '128x128',
   '96x96',
   '72x72',
   '64x64',
   '48x48',
   '36x36',
   '32x32',
   '24x24',
   '22x22',
   '16x16'
}

-- List of supported icon formats. Ignore SVG because Awesome doesn't
-- support it.
local icon_formats = { "png", "xpm" }

-- Returns an array of all starting from the specified one. Example:
-- range(3, 5) => [3, 4, 5, 1, 2].

local function range(from, all_count)
   r = {}
   for i = from, all_count do
      table.insert(r, i)
   end
   for i = 1, from-1 do
      table.insert(r, i)
   end
   return r
end

local function find(t, what)
   for i = 1, #t do
      if t[i] == what then
         return i
      end
   end
end

-- Check whether the icon format is supported.
-- @param icon_file Filename of the icon.
-- @return true if format is supported, false otherwise.
local function is_format_supported(icon_file)
   for _, f in ipairs(icon_formats) do
      if icon_file:match('%.' .. f) then
         return true
      end
   end
   return false
end

function iconic.lookup_app_icon(icon_file, args)
   args = args or {}
   args.icon_types = { '/apps/' }
   return iconic.lookup_icon(icon_file, args)
end

function iconic.lookup_status_icon(icon_file, args)
   args = args or {}
   args.icon_types = { '/status/' }
   return iconic.lookup_icon(icon_file, args)
end

--- Lookup an icon in different folders of the filesystem.
-- @param icon_file Short or full name of the icon.
-- @return full name of the icon, or default_icon if the first one was not found.
function iconic.lookup_icon(icon_file, args)
   args = args or {}
   local default_icon = args.default_icon
   local preferred_size = (args.preferred_size and find(all_icon_sizes, args.preferred_size)) or 1
   local icon_types = args.icon_types or { '/apps/', '/actions/', '/devices/',
                                           '/places/', '/categories/', '/status/' }

   if not icon_file or icon_file == "" then
      return default_icon
   end

   if icon_file:sub(1, 1) == '/' and is_format_supported(icon_file) then
      -- If the path to the icon is absolute and its format is
      -- supported, do not perform a lookup.
      return icon_file
   else
      local icon_path = {}
      local icon_theme_paths = {}
      local icon_theme = theme.icon_theme
      if icon_theme then
         table.insert(icon_theme_paths, '/usr/share/icons/' .. icon_theme .. '/')
      end
      table.insert(icon_theme_paths, '/usr/share/icons/hicolor/') -- fallback theme

      for i, icon_theme_directory in ipairs(icon_theme_paths) do
         for _, idx in ipairs(range(preferred_size, #all_icon_sizes)) do
            local size = all_icon_sizes[idx]
            for _, type in ipairs(icon_types) do
               table.insert(icon_path, icon_theme_directory .. size .. type)
            end
         end
      end
      -- lowest priority fallbacks
      table.insert(icon_path, '/usr/share/pixmaps/')
      table.insert(icon_path, '/usr/share/icons/')

      for i, directory in ipairs(icon_path) do
         if is_format_supported(icon_file) and util.file_readable(directory .. icon_file) then
            return directory .. icon_file
         else
            -- Icon is probably specified without path and format,
            -- like 'firefox'. Try to add supported extensions to
            -- it and see if such file exists.
            for _, format in ipairs(icon_formats) do
               local possible_file = directory .. icon_file .. "." .. format
               if util.file_readable(possible_file) then
                  return possible_file
               end
            end
         end
      end
      return default_icon
   end
end

return iconic
