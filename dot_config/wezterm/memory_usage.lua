local wezterm = require 'wezterm'

-- Function to get memory statistics from /proc/meminfo
function get_memory_stats()
  local file = io.open("/proc/meminfo", "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()

  local mem_total = 0
  local mem_available = 0
  local mem_free = 0
  local buffers = 0
  local cached = 0

  for line in content:gmatch("[^\r\n]+") do
    if line:match("^MemTotal:") then
      mem_total = tonumber(line:match("%d+")) or 0
    elseif line:match("^MemAvailable:") then
      mem_available = tonumber(line:match("%d+")) or 0
    elseif line:match("^MemFree:") then
      mem_free = tonumber(line:match("%d+")) or 0
    elseif line:match("^Buffers:") then
      buffers = tonumber(line:match("%d+")) or 0
    elseif line:match("^Cached:") then
      cached = tonumber(line:match("%d+")) or 0
    end
  end

  -- Calculate used memory (more accurate than just MemTotal - MemFree)
  local mem_used = mem_total - mem_available

  return {
    total = mem_total * 1024,         -- Convert from KB to bytes
    used = mem_used * 1024,           -- Convert from KB to bytes
    available = mem_available * 1024, -- Convert from KB to bytes
    free = mem_free * 1024,           -- Convert from KB to bytes
    buffers = buffers * 1024,         -- Convert from KB to bytes
    cached = cached * 1024            -- Convert from KB to bytes
  }
end

-- Function to get current memory usage
function calculate_memory_usage()
  local stats = get_memory_stats()
  if not stats or stats.total == 0 then
    return 0
  end

  local usage_percent = (stats.used / stats.total) * 100

  -- Debug output
  print(string.format("Memory: %.1f%% used (%.1fG/%.1fG)",
    usage_percent, stats.used / (1024 * 1024 * 1024), stats.total / (1024 * 1024 * 1024)))

  return usage_percent
end

-- Format memory usage for display with fixed width
function format_memory_usage(usage)
  return string.format("🧠 %5.1f%%", usage)
end

-- Alternative: Show usage with memory amounts (fixed width)
function format_memory_usage_detailed(usage)
  local stats = get_memory_stats()
  if not stats or stats.total == 0 then
    return "🧠   0.0%"
  end

  local format_bytes = function(bytes)
    if bytes >= 1024 * 1024 * 1024 then
      return string.format("%5.1fG", bytes / (1024 * 1024 * 1024))
    elseif bytes >= 1024 * 1024 then
      return string.format("%5.1fM", bytes / (1024 * 1024))
    else
      return string.format("%5.1fK", bytes / 1024)
    end
  end

  return string.format("🧠 %5.1f%% (%s/%s)", usage, format_bytes(stats.used), format_bytes(stats.total))
end

return {
  get_memory_stats = get_memory_stats,
  calculate_memory_usage = calculate_memory_usage,
  format_memory_usage = format_memory_usage,
  format_memory_usage_detailed = format_memory_usage_detailed
}
