-- Onscreen widgets module for Serenity theme

local awful = require('awful')
local infojets = require("infojets")
local pango = infojets.util.pango
local wibox = require("wibox")
local scheduler = require("scheduler")

local onscreen = {}
local config = {}

function onscreen.init()
   if theme.onscreen_config then
      config = theme.onscreen_config
   end
   onscreen.init_processwatcher()
   onscreen.init_calendar()
end

function onscreen.init_processwatcher()
   local c = config.processwatcher or {}
   local wheight = c.height or 193
   local wb = infojets.create_wibox({ width = c.width or 200, height = wheight,
                                      x = c.x or -26, y = c.y or -31,
                                      bg_color = theme.bg_onscreen })
   infojets.processwatcher.default.current_file = 2
   w = infojets.processwatcher.new()
   w:set_process_sorters({ { name = "Top CPU",
                             sort_by = "pcpu",
                             ignore = { "defunct", "migration" } },
                           { name = "Top memory",
                             sort_by = "rss",
                             ignore = { "defunct", "migration" } } })

   w.font = 'DejaVu Sans Mono 10'
   w.title_font = 'Helvetica 10'
   w:calculate_line_count(wheight)
   w.line_length = c.line_length or 40
   w:run()

   wb:set_widget(w.widget)
end

function onscreen.init_calendar()
   local c = config.calendar or {}
   local editor = "ec"

   local orglendar = require('orglendar')
   orglendar.files = { "/home/unlogic/Documents/Notes/edu.org",
                       gcal_org }
   orglendar.text_color = c.text_color or theme.fg_focus
   orglendar.today_color = c.today_color or theme.motive
   orglendar.event_color = theme.fg_onscreen
   orglendar.font = "DejaVu Sans Mono 10"
   orglendar.char_width = 8.20
   orglendar.limit_todo_length = c.limit_todo_length or 50
   orglendar.parse_on_show = false

   local cal_box_height = c.cal_height or 120
   local cal_box = infojets.create_wibox({ width = c.cal_width or 170, height = cal_box_height,
                                           x = c.cal_x or -35, y = c.cal_y or 45,
                                           bg_color = theme.bg_onscreen })
   infojets.reposition_wibox(cal_box)
   local cal_layout = wibox.layout.align.horizontal()
   local cal_tb = wibox.widget.textbox()
   cal_tb:set_valign("top")
   cal_layout:set_right(cal_tb)
   cal_box:set_widget(cal_layout)

   local todo_box = infojets.create_wibox({ width = c.todo_width or 300,
                                            height = c.todo_height or 375,
                                            x = c.todo_x or -30, y = (c.todo_y or 47) + cal_box_height,
                                            bg_color = theme.bg_onscreen })
   local todo_tb = wibox.widget.textbox()
   local todo_layout = wibox.layout.align.horizontal()
   todo_tb:set_valign("top")
   todo_layout:set_left(todo_tb)
   todo_box:set_widget(todo_layout)

   local offset = 0

   local update_orglendar =
      function(inc_offset)
      offset = offset + (inc_offset or 0)
      local cal, todo = orglendar.get_calendar_and_todo_text(offset)

      cal_tb:set_markup(cal)
      todo_tb:set_markup(todo)
      todo_box.width = orglendar.limit_todo_length * orglendar.char_width
      infojets.reposition_wibox(todo_box)
      end

      cal_tb:buttons(awful.util.table.join(
                        awful.button({ }, 2,
                                     function ()
                                        offset = 0
                                        update_orglendar()
                                     end),
                        awful.button({ }, 4,
                                     function ()
                                        update_orglendar(-1)
                                     end),
                        awful.button({ }, 5,
                                     function ()
                                        update_orglendar(1)
                                     end)))
      todo_tb:buttons(awful.util.table.join(
                         awful.button({ }, 1,
                                      function ()
                                         awful.util.spawn(editor .. " " .. orglendar.files[1])
                                      end),
                         awful.button({ }, 4,
                                      function ()
                                         update_orglendar(-1)
                                      end),
                         awful.button({ }, 5,
                                      function ()
                                         update_orglendar(1)
                                      end),
                         awful.button({ }, 3,
                                      function ()
                                         update_gcal_file()
                                         orglendar.parse_agenda()
                                         update_orglendar()
                                      end)))
      scheduler.register_recurring("orglendar_update", 600, update_orglendar)
end

return onscreen
