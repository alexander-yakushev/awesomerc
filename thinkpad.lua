local awful = require('awful')
local utility = require('utility')

local thinkpad = { touchpad = {},
                   power = {} }

function thinkpad.touchpad.enable(value)
   local value = value and 0 or 1
   awful.util.spawn("synclient TouchpadOff=" .. value)
end

function thinkpad.touchpad.toggle()
   local _, _, state = string.find(utility.pslurp("synclient -l | grep TouchpadOff",
                                            "*line"), ".*(%d)$")
   state = (state == "0")
   thinkpad.touchpad.enable(not state)
end

function thinkpad.power.screenlock()
   os.execute(userdir .. "/scripts/screenlock")
end

return thinkpad
