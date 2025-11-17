local wezterm = require 'wezterm'

local last_time = os.time()
local last_cpu_stats = nil
local current_usage = 0

-- Function to get CPU statistics from /proc/stat
function get_cpu_stats()
  local file = io.open("/proc/stat", "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()

  -- Parse the first line (total CPU usage)
  for line in content:gmatch("[^\r\n]+") do
    if line:match("^cpu ") then
      local fields = {}
      for field in line:gmatch("%S+") do
        table.insert(fields, field)
      end

      if #fields >= 8 then
        -- Fields: user, nice, system, idle, iowait, irq, softirq, steal
        local user = tonumber(fields[2] or 0)
        local nice = tonumber(fields[3] or 0)
        local system = tonumber(fields[4] or 0)
        local idle = tonumber(fields[5] or 0)
        local iowait = tonumber(fields[6] or 0)
        local irq = tonumber(fields[7] or 0)
        local softirq = tonumber(fields[8] or 0)
        local steal = tonumber(fields[9] or 0)

        local total = user + nice + system + idle + iowait + irq + softirq + steal
        local non_idle = user + nice + system + irq + softirq + steal

        return {
          total = total,
          non_idle = non_idle,
          idle = idle + iowait
        }
      end
      break
    end
  end

  return nil
end

-- Function to calculate CPU usage percentage
function calculate_cpu_usage()
  local now = os.time()
  local elapsed = now - last_time

  if elapsed >= 1 then -- Update at most once per second
    local current_stats = get_cpu_stats()

    if current_stats and last_cpu_stats then
      local total_diff = current_stats.total - last_cpu_stats.total
      local non_idle_diff = current_stats.non_idle - last_cpu_stats.non_idle

      if total_diff > 0 then
        current_usage = (non_idle_diff / total_diff) * 100
      else
        current_usage = 0
      end

      -- Debug output
      print(string.format("CPU Usage: %.1f%% (total_diff: %d, non_idle_diff: %d)",
        current_usage, total_diff, non_idle_diff))
    end

    last_cpu_stats = current_stats
    last_time = now
  end

  return current_usage
end

-- Format CPU usage for display
function format_cpu_usage(usage)
  return string.format("🖥️ %5.1f%%", usage)
end

-- If you want to keep both versions
function format_cpu_usage_detailed(usage)
  return string.format("🖥️ %5.1f%%", usage)
end

return {
  get_cpu_stats = get_cpu_stats,
  calculate_cpu_usage = calculate_cpu_usage,
  format_cpu_usage = format_cpu_usage,
  format_cpu_usage_detailed = format_cpu_usage_detailed
}
