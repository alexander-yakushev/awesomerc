--- Custom widget library for Awesome Windows Manager.
local base = require('topjets.base')

return {
   base = base,
   clock = require('topjets.clock'),
   cpu = require('topjets.cpu'),
   memory = require('topjets.memory'),
   volume = require('topjets.volume'),
   network = require('topjets.network'),
   battery = require('topjets.battery'),
   weather = require('topjets.weather'),
   kbd = require('topjets.kbd'),
   unitybar = require('topjets.unitybar'),
   processwatcher = require('topjets.processwatcher'),

   set_tooltip_position = function (new_pos)
      base.tooltip_position = new_pos
   end
}
