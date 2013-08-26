local asyncshell = require('asyncshell')
local util = require('awful.util')
local naughty = require('naughty')

-- Module "dict"
local dict = {}

local function trim(s)
   local _, _, res = string.find(s, " *([%w ']+)")
   return res
end

function dict.handle_response(resp_file)
   resp_file:read() -- Skip first line
   if not string.match(resp_file:read(), "250 ok") then
      naughty.notify({ title = "dict.org error",
                       text = "Request is not valid" })
      return
   end
   _, _, def_count = string.find(resp_file:read(), "^%d%d%d (%d+)")
   if not def_count then
      naughty.notify({ title = "No definitions found",
                       text = "The word was not found in the dictionary"})
      return
   end
   resp_file:read() -- Useless
   local title = resp_file:read()
   local result = ""
   for l in resp_file:lines() do
      if not string.match(l, "^%.") then
         result = result .. l .. "\n"
      else
         break
      end
   end
   result = string.sub(result, 1, #result - 2)
   naughty.notify({ title = title,
                    text = result,
                    timeout = 0 })
   resp_file:close()
end

function dict.lookup_word()
   local word = util.pread("xclip -o")
   if not word or word == "" then return end
   local req = string.format('curl dict://dict.org/d:%s', trim(word))
   asyncshell.request(req, dict.handle_response)
end

return dict
