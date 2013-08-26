-- Quake like console on top
-- Similar to:
--   http://git.sysphere.org/awesome-configs/tree/scratch/drop.lua

-- But uses a different implementation. The main difference is that we
-- are able to detect the Quake console from its name
-- (QuakeConsoleNeedsUniqueName by default).

-- Use:

-- local quake = require("quake")
--
-- And then somewhere in globalkeys:
--
-- awful.key({ modkey }, "`", function() quake.toggle({ terminal = "urxvt",
--                                                      name = "QuakeUrxvt",
--                                                      height = 0.3,
--                                                      ontop = true,
--                                                      skip_taskbar = true })
--
-- If you have a rule like "awful.client.setslave" for your terminals,
-- ensure you use an exception for
-- QuakeConsoleNeedsUniqueName. Otherwise, you may run into problems
-- with focus.

local awful  = require("awful")

-- Module "quake"
local quake = { consoles = {} }

local QuakeConsole = {}

-- Display
function QuakeConsole:display()
   -- First, we locate the terminal
   local quake_client = nil
   local i = 0
   for k, c in pairs(client.get(self.screen)) do
      if c.instance == self.name then
         i = i + 1
         if i == 1 then
            quake_client = c
         else
            -- Additional matching clients, let's remove the sticky bit
            -- which may persist between awesome restarts. We don't close
            -- them as they may be valuable. They will just turn into a
            -- classic terminal.
            c.sticky = false
            c.ontop = false
            c.above = false
         end
      end
   end

   if not quake_client then
      -- The client does not exist, we spawn it
      awful.util.spawn(self.terminal .. " " .. string.format(self.argname, self.name),
		       false, self.screen)
      return
   end

   -- Compute size
   local geom = screen[self.screen].workarea
   local width, height = self.width, self.height
   if width  <= 1 then width = geom.width * width end
   if height <= 1 then height = geom.height * height end
   local x, y
   if     self.horiz == "left"  then x = geom.x
   elseif self.horiz == "right" then x = geom.width + geom.x - width
   else   x = geom.x + (geom.width - width)/2 end
   if     self.vert == "top"    then y = geom.y
   elseif self.vert == "bottom" then y = geom.height + geom.y - height
   else   y = geom.y + (geom.height - height)/2 end

   -- Resize
   awful.client.floating.set(quake_client, true)
   quake_client.border_width = 0
   quake_client.size_hints_honor = false
   quake_client:geometry({ x = x, y = y, width = width, height = height })

   -- Sticky and on top
   quake_client.ontop = self.ontop or false
   quake_client.above = self.above or false
   quake_client.skip_taskbar = self.skip_taskbar or false
   quake_client.sticky = self.sticky or false

   if self.ignore_bindings then
      quake_client:buttons({})
      quake_client:keys({})
   end

   -- Toggle display
   if self.visible then
      awful.client.movetotag(awful.tag.selected(self.screen), quake_client)
      quake_client.hidden = false
      quake_client:raise()
      client.focus = quake_client
   else -- Hide and detach tags
      if not quake_client:isvisible() then -- Terminal is on other tag, bring it here
         -- quake_client.hidden = true
         awful.client.movetotag(awful.tag.selected(self.screen), quake_client)
         self.visible = true
      else
         quake_client.hidden = true
         local ctags = quake_client:tags()
         for i, t in pairs(ctags) do
            ctags[i] = nil
         end
         quake_client:tags(ctags)
      end
   end
end

-- Create a console
function QuakeConsole:new(config)
   -- The "console" object is just its configuration.

   -- The application to be invoked is:
   --   config.terminal .. " " .. string.format(config.argname, config.name)
   config.terminal = config.terminal or "xterm" -- application to spawn
   config.name     = config.name     or "QuakeConsoleNeedsUniqueName" -- window name
   config.argname  = config.argname  or "-name %s"     -- how to specify window name

   -- If width or height <= 1 this is a proportion of the workspace
   config.height   = config.height   or 0.25	       -- height
   config.width    = config.width    or 1	       -- width
   config.vert     = config.vert     or "top"	       -- top, bottom or center
   config.horiz    = config.horiz    or "center"       -- left, right or center

   config.screen   = config.screen or mouse.screen
   config.visible  = config.visible or true

   local console = setmetatable(config, { __index = QuakeConsole })
   client.connect_signal("manage",
			  function(c)
			     if c.instance == console.name and c.screen == console.screen then
				console:display()
			     end
			  end)
   client.connect_signal("unmanage",
			  function(c)
			     if c.instance == console.name and c.screen == console.screen then
				console.visible = false
                                quake.consoles[console.screen] = nil
			     end
			  end)

   -- "Reattach" currently running QuakeConsole. This is in case awesome is restarted.
   local reattach = timer { timeout = 0 }
   reattach:connect_signal("timeout",
		       function()
			  reattach:stop()
			  console:display()
		       end)
   reattach:start()
   return console
end

-- Toggle the console
function QuakeConsole:toggle()
   self.visible = not self.visible
   self:display()
end

function quake.toggle(args)
   args.screen = args.screen or mouse.screen
   if not quake.consoles[args.screen] then
      quake.consoles[args.screen] = QuakeConsole:new(args)
   else
      quake.consoles[args.screen]:toggle()
   end
end

return setmetatable(quake, { __call = function(_, ...) return QuakeConsole:new(...) end})
