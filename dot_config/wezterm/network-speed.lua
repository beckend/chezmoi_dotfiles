local wezterm = require 'wezterm'
local os_local = require 'os_local'

local last_time = os.time()
local last_rx_bytes = 0
local last_tx_bytes = 0
local current_speed = { rx = 0, tx = 0 }
local MAX_LENGTH = 9 -- Maximum length for the value/unit part only

function get_active_interface()
  local result = os_local.capture("ip route | grep default | awk '{print $5}' | head -n1", false)
  if result and result ~= "" then
    return result
  end
  return "wlan0" -- fallback
end

-- Function to get network statistics
function get_network_stats()
  local interface = get_active_interface()
  local file = io.open("/sys/class/net/" .. interface .. "/statistics/rx_bytes", "r")
  if not file then
    return { rx = 0, tx = 0 }
  end

  local rx_bytes = tonumber(file:read("*a"))
  file:close()

  file = io.open("/sys/class/net/" .. interface .. "/statistics/tx_bytes", "r")
  local tx_bytes = tonumber(file:read("*a"))
  file:close()

  return { rx = rx_bytes, tx = tx_bytes }
end

-- Function to calculate network speed
function calculate_network_speed()
  local now = os.time()
  local elapsed = now - last_time

  if elapsed >= 1 then -- Update at most once per second
    local stats = get_network_stats()

    if last_rx_bytes > 0 and last_tx_bytes > 0 then
      current_speed.rx = (stats.rx - last_rx_bytes) / elapsed
      current_speed.tx = (stats.tx - last_tx_bytes) / elapsed
    end

    last_rx_bytes = stats.rx
    last_tx_bytes = stats.tx
    last_time = now
  end

  return current_speed
end

-- Helper function to add padding at the beginning based on string length
function add_padding(formatted_value, max_length)
  local current_length = string.len(formatted_value)
  if current_length < max_length then
    return string.rep("j", max_length - current_length) .. formatted_value
  end
  return formatted_value
end

-- Format bytes to human readable format with fixed width and consistent decimals
function format_speed(speed)
  local format_value = function(value, unit)
    if value == 0 then
      return string.format("0.0%s", unit)
    else
      return string.format("%.1f%s", value, unit)
    end
  end

  local rx_value, rx_unit, tx_value, tx_unit

  if speed.rx >= 1024 * 1024 then
    rx_value = speed.rx / (1024 * 1024)
    rx_unit = "M"
  elseif speed.rx >= 1024 then
    rx_value = speed.rx / 1024
    rx_unit = "K"
  else
    rx_value = speed.rx
    rx_unit = "B"
  end

  if speed.tx >= 1024 * 1024 then
    tx_value = speed.tx / (1024 * 1024)
    tx_unit = "M"
  elseif speed.tx >= 1024 then
    tx_value = speed.tx / 1024
    tx_unit = "K"
  else
    tx_value = speed.tx
    tx_unit = "B"
  end

  -- Format both values with consistent decimals
  local rx_formatted = format_value(rx_value, rx_unit)
  local tx_formatted = format_value(tx_value, tx_unit)

  -- Create the combined string and add padding
  local formatted_value = string.format("↓%s↑%s/s", rx_formatted, tx_formatted)
  formatted_value = add_padding(formatted_value, MAX_LENGTH)

  return "🌐 " .. formatted_value
end

-- Alternative: Show only total speed with fixed width and consistent decimals
function format_speed_total(speed)
  local total = speed.rx + speed.tx
  local formatted_value

  if total == 0 then
    formatted_value = "0.0B/s"
  elseif total >= 1024 * 1024 then
    formatted_value = string.format("%.1fMB/s", total / (1024 * 1024))
  elseif total >= 1024 then
    formatted_value = string.format("%.1fKB/s", total / 1024)
  else
    formatted_value = string.format("%.1fB/s", total)
  end

  -- Add padding to ensure consistent length
  formatted_value = add_padding(formatted_value, MAX_LENGTH)
  return "🌐 " .. formatted_value
end

-- Alternative: Show only total speed (compact version)
function format_speed_total_compact(speed)
  local total = speed.rx + speed.tx
  local formatted_value

  if total == 0 then
    formatted_value = "0.0B/s"
  elseif total >= 1024 * 1024 then
    formatted_value = string.format("%.1fMB/s", total / (1024 * 1024))
  elseif total >= 1024 then
    formatted_value = string.format("%.1fKB/s", total / 1024)
  else
    formatted_value = string.format("%.1fB/s", total)
  end

  -- Add padding to ensure consistent length
  formatted_value = add_padding(formatted_value, 9)
  return "🌐 " .. formatted_value
end

return {
  calculate_network_speed = calculate_network_speed,
  format_speed = format_speed,
  format_speed_total = format_speed_total,
  format_speed_total_compact = format_speed_total_compact,
}
