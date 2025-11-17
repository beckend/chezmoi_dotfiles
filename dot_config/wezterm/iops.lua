local wezterm = require 'wezterm'

local last_time = os.time()
local last_read_ops = nil
local last_write_ops = nil
local current_iops = { read = 0, write = 0 }
local MAX_LENGTH = 15 -- Maximum length for the value/unit part only

-- Function to get disk statistics from /proc/diskstats
function get_disk_stats()
  local file = io.open("/proc/diskstats", "r")
  if not file then
    return { read_ops = 0, write_ops = 0 }
  end

  local content = file:read("*a")
  file:close()

  local total_read_ops = 0
  local total_write_ops = 0

  for line in content:gmatch("[^\r\n]+") do
    local fields = {}
    for field in line:gmatch("%S+") do
      table.insert(fields, field)
    end

    if #fields >= 11 then
      local device_name = fields[3]
      local minor_number = tonumber(fields[2] or 0)

      -- Better device filtering logic:
      -- 1. Skip partitions (minor number != 0)
      -- 2. Skip virtual devices (zram, loop, fd)
      -- 3. Skip DM devices (dm-*) unless you want to include them
      if minor_number == 0 and
          not device_name:match("^zram") and
          not device_name:match("^loop") and
          not device_name:match("^fd") and
          not device_name:match("^dm%-") then
        local read_ops = tonumber(fields[4] or 0)
        local write_ops = tonumber(fields[8] or 0)

        total_read_ops = total_read_ops + read_ops
        total_write_ops = total_write_ops + write_ops

        print(string.format("Included device: %s, Read: %d, Write: %d",
          device_name, read_ops, write_ops))
      else
        print(string.format("Excluded device: %s (minor: %d)", device_name, minor_number))
      end
    end
  end

  print(string.format("Total - Read Ops: %d, Write Ops: %d", total_read_ops, total_write_ops))

  return { read_ops = total_read_ops, write_ops = total_write_ops }
end

-- Alternative simpler approach: sum all devices except known virtual ones
function get_disk_stats_simple()
  local file = io.open("/proc/diskstats", "r")
  if not file then
    return { read_ops = 0, write_ops = 0 }
  end

  local content = file:read("*a")
  file:close()

  local total_read_ops = 0
  local total_write_ops = 0

  for line in content:gmatch("[^\r\n]+") do
    local fields = {}
    for field in line:gmatch("%S+") do
      table.insert(fields, field)
    end

    if #fields >= 11 then
      local device_name = fields[3]

      -- Only exclude known virtual devices
      if not device_name:match("^zram") and
          not device_name:match("^loop") and
          not device_name:match("^fd") then
        local read_ops = tonumber(fields[4] or 0)
        local write_ops = tonumber(fields[8] or 0)

        total_read_ops = total_read_ops + read_ops
        total_write_ops = total_write_ops + write_ops

        print(string.format("Included device: %s, Read: %d, Write: %d",
          device_name, read_ops, write_ops))
      else
        print(string.format("Excluded device: %s", device_name))
      end
    end
  end

  print(string.format("Total (simple) - Read Ops: %d, Write Ops: %d", total_read_ops, total_write_ops))

  return { read_ops = total_read_ops, write_ops = total_write_ops }
end

-- Function to calculate IOPS
function calculate_iops()
  local now = os.time()
  local elapsed = now - last_time

  if elapsed >= 1 then
    -- Try the simple approach first
    local stats = get_disk_stats_simple()

    if last_read_ops and last_write_ops then
      current_iops.read = (stats.read_ops - last_read_ops) / elapsed
      current_iops.write = (stats.write_ops - last_write_ops) / elapsed
    else
      current_iops.read = 0
      current_iops.write = 0
    end

    last_read_ops = stats.read_ops
    last_write_ops = stats.write_ops
    last_time = now

    print(string.format("IOPS: R:%.1f W:%.1f", current_iops.read, current_iops.write))
  end

  return current_iops
end

-- Helper function to add padding at the beginning based on string length
function add_padding(formatted_value, max_length)
  local current_length = string.len(formatted_value)
  if current_length < max_length then
    return string.rep(" ", max_length - current_length) .. formatted_value
  end
  return formatted_value
end

-- Format function with consistent padding
function format_iops_total(iops)
  local read, write = iops.read, iops.write
  local read_throughput = read * 4096
  local write_throughput = write * 4096

  local format_throughput = function(bytes)
    local value, unit

    if bytes == 0 then
      value = 0.0
      unit = "B"
    elseif bytes >= 1024 * 1024 * 1024 then
      value = bytes / (1024 * 1024 * 1024)
      unit = "G"
    elseif bytes >= 1024 * 1024 then
      value = bytes / (1024 * 1024)
      unit = "M"
    elseif bytes >= 1024 then
      value = bytes / 1024
      unit = "K"
    else
      value = bytes
      unit = "B"
    end

    -- Format with unit and /s together
    local formatted = string.format("%.1f%s/s", value, unit)

    return add_padding(formatted, 9)
  end

  -- Format the values with padding (including /s)
  local read_formatted = format_throughput(read_throughput)
  local write_formatted = format_throughput(write_throughput)

  return "💾 R:" .. read_formatted .. " W:" .. write_formatted
end

-- Alternative: Show only total IOPS with padding
function format_iops_total_compact(iops)
  local total = iops.read + iops.write
  local total_throughput = total * 4096
  local formatted_value

  if total_throughput >= 1024 * 1024 * 1024 then
    formatted_value = string.format("%.1fG/s", total_throughput / (1024 * 1024 * 1024))
  elseif total_throughput >= 1024 * 1024 then
    formatted_value = string.format("%.1fM/s", total_throughput / (1024 * 1024))
  elseif total_throughput >= 1024 then
    formatted_value = string.format("%.1fK/s", total_throughput / 1024)
  else
    formatted_value = string.format("%.0fB/s", total_throughput)
  end

  -- Add padding to ensure consistent length
  formatted_value = add_padding(formatted_value, MAX_LENGTH)
  return "💾 " .. formatted_value
end

return {
  get_disk_stats = get_disk_stats,
  get_disk_stats_simple = get_disk_stats_simple,
  calculate_iops = calculate_iops,
  format_iops_total = format_iops_total,
  format_iops_total_compact = format_iops_total_compact
}
