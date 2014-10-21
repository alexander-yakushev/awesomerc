local asyncshell = require('asyncshell')
local naughty = require('naughty')

local currencies = { invalid_time = 86400,
                     interested_in = { "USD", "EUR", "NOK", "UAH" } }

local cached_rates = {}

local function get_cached_rate(from, to)
   if cached_rates[from] ~= nil then
      return cached_rates[from][to]
   end
end

local function cache_rate(from, to, rate)
   if cached_rates[from] == nil then
      cached_rates[from] = {}
   end
   if cached_rates[to] == nil then
      cached_rates[to] = {}
   end
   cached_rates[from][to] = { rate = rate, time = os.time() }
   cached_rates[to][from] = { rate = 1 / rate, time = os.time() }
end

local function build_req(from, to)
   return "http://rate-exchange.appspot.com/currency?from=" .. from:upper() .. "&to=" .. to:upper()
end

local function request_rate_from_api(from, to)
   local f = asyncshell.demand("curl '" .. build_req(from, to) .. "'", 2)
   local res = f:read()
   f:close()
   if res ~= nil then
      local rate = tonumber(res:match('.*"rate": ([^,]+).*'))
      if rate then
         cache_rate(from, to, rate)
         return rate
      end
   end
end

function currencies.get_rate(from, to)
   from = from:upper()
   to = to:upper()
   local cached = get_cached_rate(from, to)
   if (cached ~= nil) and (os.time() - cached.time < currencies.invalid_time) then
      return cached.rate
   else
      local rate = request_rate_from_api(from, to)
      if not rate then
         if cached then
            naughty.notify({ title = string.format("Couldn't return rates for: %1, %2", from, to),
                             text = "Using cached values." })
            rate = cached.rate
         else
            return nil
         end
      end
      return rate
   end
end

function currencies.recalc(str)
   local val, curr = str:match("([%d%.]+)%s*(.+)")
   val = tonumber(val)
   curr = curr:upper()
   local result = ""
   for i, c in ipairs(currencies.interested_in) do
      if c ~= curr then
         result = string.format("%s%4.2f %s", result, val * currencies.get_rate(curr, c), c)
         if i ~= #currencies.interested_in then
            result = result .. "\n"
         end
      end
   end
   naughty.notify({ title = val .. " " .. curr,
                    text = result, timeout = 0 })
end

return currencies
