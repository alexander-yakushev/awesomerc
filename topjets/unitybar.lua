local wibox = require('wibox')
local l = require('layout')
local awful = require('awful')
local iconic = require('iconic')
local utility = require('utility')
local theme = require('beautiful')

-- Module topjets.unitybar
local unitybar = { tag_widgets = {} }

function unitybar.update_tag(bar, tag, wdg)
   wdg:reset()

   local visible_clients, pivot, urgent = {}, 0, false
   for _, c in ipairs(tag:clients()) do
      if not (c.skip_taskbar or c.hidden
                 or c.type == "splash" or c.type == "dock" or c.type == "desktop")
      then
         local im = wibox.widget.imagebox()
         im:set_image(c.icon or unitybar.args.default_icon)
         im.client = c
         im:buttons(utility.keymap("LMB", function()
                                      awful.tag.viewonly(tag)
                                      c:raise()
                                      client.focus = c
         end))
         table.insert(visible_clients, im)
         if client.focus == c then
            pivot = #visible_clients
         end
         if c.urgent then
            urgent = true
         end
      end
   end

   local middle = l.center { horizontal = true }
   local bgb = l.background { l.margin { middle, margin = 2 },
                              color = urgent and unitybar.args.bg_urgent }
   bgb.border = tag.selected
   bgb.draw = unitybar.draw_tagbg_border
   wdg:set_widget(bgb)

   local unfocused_size, focused_size
   if bar.thin then
      unfocused_size = math.floor((bar.width - 4) / 2)
      focused_size = bar.width - 4 -1
   else
      unfocused_size = math.max(math.floor((bar.width - 5) / 3), 18)
      focused_size = bar.width - 4 - unfocused_size - 1
   end

   if #visible_clients == 0 then
      local num = wibox.widget.textbox(string.format('<span color="%s">%s</span>',
                                                     unitybar.args.fg_normal, tag.name))
      middle:buttons(utility.keymap("LMB", function() awful.tag.viewonly(tag) end))
      middle:set_middle( l.center { num, horizontal = true, vertical = true } )
      return
   end

   if pivot ~= 0 then
      local back = l.bag {}
      local content =
         l.fixed { l.center { l.exact { visible_clients[pivot], size = focused_size },
                              vertical = true },
                   (#visible_clients > 1) and back or nil }
      middle:set_middle(content)

      for i = pivot - 1, 1, -1 do
         back:add(l.exact { visible_clients[i], size = unfocused_size })
      end
      for i = #visible_clients, pivot + 1, -1 do
         back:add(l.exact { visible_clients[i], size = unfocused_size })
      end
   else
      local apps = l.bag {}
      middle:set_middle(apps)
      for i = 1, #visible_clients do
         apps:add( l.exact { visible_clients[i], size = unfocused_size } )
      end
   end
end

function unitybar.draw_tagbg_border(wdg, wb, cr, width, height)
   if not wdg.widget then
      return
   end
   cr:save()

   if wdg.background then
      cr:set_source(wdg.background)
      cr:paint()
   end
   if wdg.border then
      local margin = 2
      local corner_radius = 5

      local x, y = margin, margin
      local w = width - margin * 2
      local h = height - margin * 2
      local aspect = width / height
      local radius = corner_radius / aspect;
      local degrees = 3.14 / 180.0;

      cr:new_sub_path()
      cr:arc(x + w - radius, y + radius, radius, -90 * degrees, 0 * degrees)
      cr:arc(x + w - radius, y + h - radius, radius, 0 * degrees, 90 * degrees);
      cr:arc(x + radius, y + h - radius, radius, 90 * degrees, 180 * degrees);
      cr:arc(x + radius, y + radius, radius, 180 * degrees, 270 * degrees);
      cr:close_path(cr)

      cr:set_source_rgba(1, 1, 1, 1)
      cr:set_line_width(1)
      cr:stroke(cr)
   end

   cr:restore()
   wibox.layout.base.draw_widget(wb, cr, wdg.widget, 0, 0, width, height)
end

local tag_signals = { "property::activated", "property::selected",
                      "property::hide", "property::name",
                      "property::screen", "property::index" }

local client_signals = {"property::urgent", "property::sticky",
                        "property::ontop", "property::floating",
                        "property::maximized_horizontal",
                        "property::maximized_vertical",
                        "property::minimized", "property::name",
                        "property::icon_name", "property::icon",
                        "property::skip_taskbar", "property::screen",
                        "property::hidden", "tagged", "untagged",
                        "unmanage", "list", "focus", "unfocus" }

function unitybar.new(args)
   local args = args or {}
   args.default_icon = args.default_icon or iconic.lookup_icon("application-default-icon")
   args.fg_normal = args.fg_normal or theme.fg_normal or "#ffffff"
   args.bg_urgent = args.bg_urgent or theme.bg_urgent or "#ff0000"
   unitybar.args = args

   local s = args.screen or 1
   local tags = awful.tag.gettags(s)

   unitybar.tag_widgets[s] = {}

   local bar = l.fixed { vertical = not args.horizontal }
   bar.width = args.width or 60
   bar.thin = args.thin

   for _, tag in ipairs(tags) do
      local tag_widget = l.single {}
      local u = function() unitybar.update_tag(bar, tag, tag_widget) end
      for _, signal in ipairs(tag_signals) do
         awful.tag.attached_connect_signal(s, signal, u)
      end
      for _, signal in ipairs(client_signals) do
         client.connect_signal(signal, u)
      end
      u()
      table.insert(unitybar.tag_widgets[s], tag_widget)
      bar:add(l.exact { tag_widget,
                        width = args.thin and (bar.width * 3) or bar.width,
                        height = bar.width })
   end
   return bar
end

return setmetatable(unitybar, { __call = function(_, ...) return unitybar.new(...) end})
