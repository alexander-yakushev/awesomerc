local object = require('gears.object')
local sunriseset = require('lustrous.sunriseset')
local scheduler = require('scheduler')

-- Module lustrous
local lustrous = object()

lustrous.update_interval = 600

local current_time = nil
local srs_args
local callbacks = {}

function lustrous.init(args)
   srs_args = args
   lustrous.update_time()

   scheduler.register_recurring("lustrous_check_time", lustrous.update_interval, lustrous.update_time)

   return current_time
end

function lustrous.get_time()
   local now = os.time()
   local rise, set = sunriseset(srs_args)

   local new_time
   if now > rise and now < set then -- After sunrise, before sunset
      return "day", rise, set
   else
      return "night", rise, set
   end
end

function lustrous.update_time()
   local new_time = lustrous.get_time()

   if current_time and current_time ~= new_time then
      lustrous:emit_signal("lustrous::time_changed")
   end

   current_time = new_time
end

return lustrous
