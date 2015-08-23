local wlayout = require("wibox.layout")

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

return layout
