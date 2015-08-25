local private = {}

private.user = { name = "username",
                 loc = { lat = 51, lon = 5, gmt = 1 }}

-- For weather API key register at https://forecast.io/
private.weather = { api_key = "api key here" }

return private
