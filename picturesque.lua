-- Automatically downloads and sets wallpapers from 4walled.com.
-- Requires asyncshell (https://gist.github.com/alexander-yakushev/1466863)
-- For configuration details see http://awesome.naquadah.org/wiki/Picturesque
-- How to use:
--    local picturesque = require('picturesque')
--    local t = timer { timeout = 3600 }
--    t:connect_signal("timeout", picturesque.change_image)
--    t:start()

local awful = require('awful')
local asyncshell = require('asyncshell')
local gears = require('gears')
local format = string.format

local picturesque =
   { cache_folder = awful.util.getdir("cache") .. "/picturesque/",
     sfw = true,
     resolution = "auto",
     callback = function (img_file)
           for s = 1, screen.count() do
              gears.wallpaper.maximized(img_file, s, true)
           end
     end
   }

local get_url_cmd = "curl -s http://4walled.cc/search.php\\?tags\\=\\&board\\=\\&width_aspect\\=%sx%s\\&searchstyle\\=larger\\&sfw\\=%s\\&search\\=random 2> /dev/null | grep -m 1 '<li class='"
local get_img_url_cmd = "curl -s %s 2> /dev/null | grep -m 1 'href=\"http'"
local fetch_img_cmd = "wget -q %s -O %s 2> /dev/null"

local function get_random_page_url (f)
   local s = f:read()
   f:close()
   return s:match("href='([^']+)'")
end

local function get_image_url (f)
   local s = f:read()
   f:close()
   return s:match('href="([^"]+)"')
end

local function get_aspects (w, h)
   return w, math.floor(w / h * 100)
end

local function get_resolution (resolution)
   if type(resolution) == "function" then
      return resolution()
   elseif resolution == "auto" then
      return screen[1].geometry.width, screen[1].geometry.height
   else
      return resolution:match("(%d+)x(%d+)")
   end
end

function picturesque.change_image ()
   local name = picturesque.cache_folder .. os.date("%Y_%m_%d_%H_%M") .. ".jpg"
   local w, h = get_aspects(get_resolution(picturesque.resolution))
   asyncshell.request(format(get_url_cmd, w, h, picturesque.sfw and "0" or "\\&"),
                      function (f)
                         local url = get_random_page_url(f)
                         asyncshell.request(format(get_img_url_cmd, url),
                                            function (f)
                                               local img_url = get_image_url(f)
                                               asyncshell.request(format(fetch_img_cmd, img_url, name),
                                                                  function (f)
                                                                     f:close()
                                                                     picturesque.callback(name)
                                                                  end)
                                            end)
                      end)
end

return picturesque
