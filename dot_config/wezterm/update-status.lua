local wezterm = require 'wezterm'
local os_local = require 'os_local'
local network_speed = require 'network-speed'
local iops = require 'iops'
local cpu_usage = require 'cpu_usage'
local memory_usage = require 'memory_usage'

-- Define color palette outside the function
local colors = {
  "#3b82f6", -- Vibrant blue
  "#10b981", -- Emerald green
  "#8b5cf6", -- Purple
  "#f59e0b", -- Amber
  "#ec4899", -- Pink
  "#06b6d4", -- Cyan
  "#84cc16", -- Lime
  "#6366f1", -- Indigo
}

local text_fg = "#fffafa"

wezterm.on("update-right-status", function(window, pane)
  local cells = {}

  -- Get network speed
  local net_speed = network_speed.calculate_network_speed()
  table.insert(cells, network_speed.format_speed_total(net_speed))

  -- Get IOPS load
  local iops_load = iops.calculate_iops()
  table.insert(cells, iops.format_iops_total(iops_load))

  -- Get Memory usage
  -- local memory_usage_value = memory_usage.calculate_memory_usage()
  -- table.insert(cells, memory_usage.format_memory_usage(memory_usage_value))

  -- Get CPU usage
  -- local cpu_usage_value = cpu_usage.calculate_cpu_usage()

  -- Date/time
  -- table.insert(cells, "🗓️ " .. wezterm.strftime("%a %b %-d %H:%M"));

  -- Battery info
  -- for _, b in ipairs(wezterm.battery_info()) do
  --   table.insert(cells, "⚡  " .. string.format("%.0f%%", b.state_of_charge * 100))
  -- end

  -- WiFi SSID
  -- local wifi_ok, wifi_ssid = pcall(os_local.capture, "iwgetid -r", false)
  -- if wifi_ok and wifi_ssid and wifi_ssid ~= "" then
  --   table.insert(cells, "🛜 " .. wifi_ssid)
  -- else
  --   table.insert(cells, "🛜 No WiFi")
  -- end

  -- Figure out the cwd and host of the current pane.
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri then
    local path_modified = cwd_uri.path:gsub(wezterm.home_dir, "~")
    table.insert(cells, path_modified)
  end


  local elements = {};
  local num_cells = 0;

  -- Round-robin color selection function
  local function get_color(index)
    return colors[((index - 1) % #colors) + 1]
  end

  -- Translate a cell into elements
  local function push(text, is_last)
    local cell_no = num_cells + 1
    local cell_color = get_color(cell_no)
    local next_cell_color = get_color(cell_no + 1)

    if num_cells == 0 then
      -- First cell: solid left arrow with cell color
      table.insert(elements, { Foreground = { Color = cell_color } })
      table.insert(elements, { Text = utf8.char(0xe0b2) }) -- SOLID_LEFT_ARROW
    end

    -- Cell content
    table.insert(elements, { Foreground = { Color = text_fg } })
    table.insert(elements, { Background = { Color = cell_color } })
    table.insert(elements, { Text = " " .. text .. " " })

    if not is_last then
      -- Separator arrow for next cell
      table.insert(elements, { Foreground = { Color = next_cell_color } })
      table.insert(elements, { Background = { Color = cell_color } })
      table.insert(elements, { Text = utf8.char(0xe0b2) }) -- SOLID_LEFT_ARROW
    end

    num_cells = num_cells + 1
  end

  -- Process all cells
  if #cells > 0 then
    for i, cell in ipairs(cells) do
      push(cell, i == #cells)
    end
  else
    push("No status", true)
  end

  window:set_right_status(wezterm.format(elements))
end)
