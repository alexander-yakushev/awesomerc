local util = require('awful.util')
local utility = require('utility')

-- Module rcloader
local rcloader = { default_rc_folder = util.getdir("config"),
                   system_default_rc = "/etc/xdg/awesome/rc.lua",
                   rc_name_map = { },
                   all_rcs = {} }
rcloader.rc_name_map.default = rcloader.system_default_rc

local cache_file = util.getdir("cache") .. "/current_rc_name"

local function n_info(text)
   print("INFO: rcloader: " .. text)
end

local function n_error(text)
   print("ERROR: rcloader: " .. text)
end

local function read_current_rc_name()
   return utility.slurp(cache_file, "*line")
end

function rcloader.load(name)
   if rcloader.rc_name_map[name] then
      n_info("Loading " .. name)
      dofile(rcloader.rc_name_map[name])
   else
      n_error("Cannot find rc file: " .. name)
      dofile(rcloader.all_rcs[1])
   end
end

function rcloader.load_current_rc()
   if #rcloader.all_rcs == 0 then
      n_error("No user rc files were specified")
      dofile(rcloader.system_default_rc)
   else
      local name = read_current_rc_name()
      if name then
         rcloader.load(name)
      else
         n_error("Wrong current rc filename")
         dofile(rcloader.all_rcs[1])
      end
   end
end

function rcloader.set(name)
   if not rcloader.rc_name_map[name] then
      n_error("Cannot find rc file: " .. name)
      return
   end
   local f = io.open(cache_file, 'w')
   f:write(name)
   f:close()
   awesome.restart()
end

function rcloader.add_rc(name, filename)
   local fname = filename
   if string.sub(fname, 1, 1) ~= "/" then
      fname = rcloader.default_rc_folder .. "/" .. fname
   end
   rcloader.rc_name_map[name] = fname
   table.insert(rcloader.all_rcs, fname)
end

rcloader.add_rc("core", "x220.lua")
rcloader.load_current_rc()
--rcloader.load("default")
