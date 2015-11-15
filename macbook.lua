local utility = require("utility")
local cmd = utility.cmd

globalkeys = utility.keymap(
   globalkeys,
   "XF86KbdBrightnessUp", cmd("kbdlight up 10"),
   "XF86KbdBrightnessDown", cmd("kbdlight down 10")
)

root.keys(globalkeys)
