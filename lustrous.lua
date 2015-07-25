-- Module for calculating sunrise/sunset times for a given location
-- Based on algorithm by United Stated Naval Observatory, Washington
-- Link: http://williams.best.vwh.net/sunrise_sunset_algorithm.htm
-- @author Alexander Yakushev
-- @copyright 2012 Alexander Yakushev

-- Module lustrous
local lustrous = {
   update_interval = 600
}

local current_time = nil
local srs_args
local rad = math.rad
local deg = math.deg
local floor = math.floor
local frac = function(n) return n - floor(n) end
local cos = function(d) return math.cos(rad(d)) end
local acos = function(d) return deg(math.acos(d)) end
local sin = function(d) return math.sin(rad(d)) end
local asin = function(d) return deg(math.asin(d)) end
local tan = function(d) return math.tan(rad(d)) end
local atan = function(d) return deg(math.atan(d)) end

local function fit_into_range(val, min, max)
   local range = max - min
   local count
   if val < min then
      count = floor((min - val) / range) + 1
      return val + count * range
   elseif val >= max then
      count = floor((val - max) / range) + 1
      return val - count * range
   else
      return val
   end
end

local function day_of_year(date)
   local n1 = floor(275 * date.month / 9)
   local n2 = floor((date.month + 9) / 12)
   local n3 = (1 + floor((date.year - 4 * floor(date.year / 4) + 2) / 3))
   return n1 - (n2 * n3) + date.day - 30
end

local function sunturn_time(date, rising, latitude, longitude, zenith, local_offset)
   local n = day_of_year(date)

   -- Convert the longitude to hour value and calculate an approximate time
   local lng_hour = longitude / 15

   local t
   if rising then -- Rising time is desired
      t = n + ((6 - lng_hour) / 24)
   else -- Setting time is desired
      t = n + ((18 - lng_hour) / 24)
   end

   -- Calculate the Sun's mean anomaly
   local M = (0.9856 * t) - 3.289

   -- Calculate the Sun's true longitude
   local L = fit_into_range(M + (1.916 * sin(M)) + (0.020 * sin(2 * M)) + 282.634, 0, 360)

   -- Calculate the Sun's right ascension
   local RA = fit_into_range(atan(0.91764 * tan(L)), 0, 360)

   -- Right ascension value needs to be in the same quadrant as L
   local Lquadrant  = floor(L / 90) * 90
   local RAquadrant = floor(RA / 90) * 90
   RA = RA + Lquadrant - RAquadrant

   -- Right ascension value needs to be converted into hours
   RA = RA / 15

   -- Calculate the Sun's declination
   local sinDec = 0.39782 * sin(L)
   local cosDec = cos(asin(sinDec))

   -- Calculate the Sun's local hour angle
   local cosH = (cos(zenith) - (sinDec * sin(latitude))) / (cosDec * cos(latitude))

   if rising and cosH > 1 then
      return "N/R" -- The sun never rises on this location on the specified date
   elseif cosH < -1 then
      return "N/S" -- The sun never sets on this location on the specified date
   end

   -- Finish calculating H and convert into hours
   local H
   if rising then
      H = 360 - acos(cosH)
   else
      H = acos(cosH)
   end
   H = H / 15

   -- Calculate local mean time of rising/setting
   local T = H + RA - (0.06571 * t) - 6.622

   -- Adjust back to UTC
   local UT = fit_into_range(T - lng_hour, 0, 24)

   -- Convert UT value to local time zone of latitude/longitude
   local LT =  UT + local_offset

   return os.time({ day = date.day, month = date.month, year = date.year,
                    hour = floor(LT), min = floor(frac(LT) * 60) })
end

function lustrous.is_dst(date)
   if date.month < 3 or date.month > 10 then return false end
   if date.month > 3 and date.month < 10 then return true end

   local previous_sunday = date.day - date.wday

   if date.month == 3 then return (previous_sunday >= 25) end
   if date.month == 10 then return (previous_sunday < 25) end

   return false
end

local function get(args)
   args = args or {}
   local date = args.date or os.date("*t")
   local lat = args.lat or 0
   local lon = args.lon or 0
   local zenith = args.zenith or 90.83

   local offset = 0
   if args.gmt ~= nil then
      offset = args.gmt
      if not args.no_dst and lustrous.is_dst(date) then
         offset = offset + 1
      end
   end

   local rise_time = sunturn_time(date, true, lat, lon, zenith, offset)
   local set_time = sunturn_time(date, false, lat, lon, zenith, offset)

   local length = (set_time - rise_time) / 3600
   return rise_time, set_time, floor(length), frac(length) * 60
end

function lustrous.get_time(args)
   local now = os.time()
   local rise, set = get(args or srs_args)

   local new_time
   if now > rise and now < set then -- After sunrise, before sunset
      return "day", rise, set
   else
      return "night", rise, set
   end
end

function lustrous.update_time(args)
   local new_time = lustrous.get_time(args)

   if current_time and current_time ~= new_time then
      lustrous:emit_signal("lustrous::time_changed")
   end

   current_time = new_time
end

function lustrous.init(args)
   srs_args = args
   if scheduler then
      scheduler.register_recurring("lustrous_check_time",
                                   lustrous.update_interval,
                                   lustrous.update_time)
   end
   return current_time
end

return lustrous
