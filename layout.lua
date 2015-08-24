local wibox = require("wibox")
local wlayout = require("wibox.layout")
local widget_base = require("wibox.widget.base")

local layout = {}

function layout.margin(m)
   if m.margin ~= nil then
      return wlayout.margin(m[1], m.margin, m.margin,
                            m.margin, m.margin)
   elseif m.margins ~= nil then
      return wlayout.margin(m[1], unpack(m.margins))
   else
      return wlayout.margin(m[1], m.margin_left or 0, m.margin_right or 0,
                            m.margin_top or 0, m.margin_bottom or 0)
   end
end

function layout.fixed(m)
   local m_linear
   if m.vertical then
      m_linear = wlayout.fixed.vertical()
   else
      m_linear = wlayout.fixed.horizontal()
   end
   for _, w in ipairs(m) do
      m_linear:add(w)
   end
   return m_linear
end

function layout.flex(m)
   local m_flex
   if m.vertical then
      m_flex = wlayout.flex.vertical()
   else
      m_flex = wlayout.flex.horizontal()
   end
   for _, w in ipairs(m) do
      m_flex:add(w)
   end
   return m_flex
end

function layout.align(m)
   local a_layout
   if m.vertical then
      a_layout = wlayout.align.vertical()
      if m.start ~= nil then
         a_layout:set_top(m.start)
      end
      if m.middle ~= nil then
         a_layout:set_middle(m.middle)
      end
      if m.finish ~= nil then
         a_layout:set_bottom(m.finish)
      end
   else
      a_layout = wlayout.align.horizontal()
      if m.start ~= nil then
         a_layout:set_left(m.start)
      end
      if m.middle ~= nil then
         a_layout:set_middle(m.middle)
      end
      if m.finish ~= nil then
         a_layout:set_right(m.finish)
      end
   end
   return a_layout
end

function layout.center(m)
   local w = m[1]
   if m.vertical then
      local v_center = wlayout.align.vertical()
      v_center:set_middle(w)
      w = v_center
   end
   if m.horizontal then
      local h_center = wlayout.align.horizontal()
      h_center:set_middle(w)
      w = h_center
   end
   return w
end

function layout.midpoint(m)
   return layout.center { m[1], horizontal = m.vertical,
                          vertical = not m.vertical }
end

function layout.exact(m)
   return wlayout.constraint(m[1], 'exact', m.size or m.width,
                             m.size or m.height)
end

function layout.constrain(m)
   return wlayout.constraint(m[1], m.strategy or 'max', m.size or m.width,
                             m.size or m.height)
end

function layout.single(m)
   return wlayout.constraint(m[1])
end

function layout.background(m)
   local bg = wibox.widget.background()
   bg:set_widget(m[1])
   if m.image then
      bg:set_bgimage(m.image)
   end
   if m.color then
      bg:set_bg(m.color)
   end
   return bg
end

local bag = {}

function bag:draw(wibox, cr, all_width, all_height)
   local rows = { { width = 0, height = 0, y = 0 }, width = 0, height = 0 }

   local function diff(a, b)
      return math.abs(a - b)
   end

   local function recalc_curr_dim()
      rows.width, rows.height = 0, 0
      for i, row in ipairs(rows) do
         row.width, row.height, row.y = 0, 0, rows.height
         for j, item in ipairs(row) do
            row.width = row.width + item.width
            row.height = math.max(row.height, item.height)
         end
         rows.width = math.max(rows.width, row.width)
         rows.height = rows.height + row.height
      end
   end

   local function add_to_best_row (widget, w, h)
      local res = {}
      local deltas = {}
      for i, row in ipairs(rows) do
         if (row.width + w < all_width) and
         (row.y + math.max(row.height, h) <= all_height) then
            table.insert(res, i)
            deltas[i] =
               diff(math.max(rows.width, row.width + w),
                    rows.height + ((h > row.height) and (h - row.height) or 0))
         else
            deltas[i] = 100000
         end
      end
      if (rows[#rows].y + rows[#rows].height + h <= all_height) and
      (w < all_width) then
         deltas[#rows+1] = diff(math.max(rows.width, w), rows.height + h)
         table.insert(res, #rows + 1)
      else
         deltas[#rows+1] = 100000
      end

      local best_delta, best_row = 100000, nil
      for i, delta in ipairs(deltas) do
         if delta < best_delta then
            best_delta = delta
            best_row = i
         end
      end

      if best_row ~= nil then
         if best_row > #rows then
            table.insert(rows, { width = 0, height = 0, y = rows.height })
         end
         table.insert(rows[best_row], { widget = widget, width = w, height = h })
         recalc_curr_dim()
      end
   end

   for k, v in pairs(self.widgets) do
      local wdg_w, wdg_h = wlayout.base.fit_widget(v, all_width, all_height)
      add_to_best_row(v, wdg_w, wdg_h)
   end

   local y = (all_height - rows.height) / 2
   for i, row in ipairs(rows) do
      local x = (all_width - row.width) / 2
      for j, item in ipairs(row) do
         wlayout.base.draw_widget(wibox, cr, item.widget, x, y, item.width, item.height)
         x = x + item.width
      end
      y = y + row.height
   end
end

function bag:add(widget)
   widget_base.check_widget(widget)
   table.insert(self.widgets, widget)
   widget:connect_signal("widget::updated", self._emit_updated)
   self._emit_updated()
end

function bag:fit(orig_width, orig_height)
   return orig_width, orig_height
end

function bag:reset()
   for k, v in pairs(self.widgets) do
      v:disconnect_signal("widget::updated", self._emit_updated)
   end
   self.widgets = {}
   self:emit_signal("widget::updated")
end

function layout.bag(m)
   local ret = widget_base.make_widget()

   for k, v in pairs(bag) do
      if type(v) == "function" then
         ret[k] = v
      end
   end

   ret.widgets = {}
   ret._emit_updated = function()
      ret:emit_signal("widget::updated")
   end

   return ret
end

return layout
