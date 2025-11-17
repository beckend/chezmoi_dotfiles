local wezterm = require 'wezterm'
local utilities = require 'utilities'
local config_base = require 'config_base'
require 'update-status'

local config = config_base.config

utilities.object_assign(config, {
  -- debug_key_events = true,
  front_end = 'WebGpu',
  -- front_end = 'OpenGL',
  enable_wayland = true,
  max_fps = 300,

  color_schemes = {
    ["Charmful Dark"] = require("charmful"),
  },
  color_scheme = "Charmful Dark",
  -- window:set_right_status() needs this bar.
  hide_tab_bar_if_only_one_tab = false,
  use_fancy_tab_bar = true,

  default_gui_startup_args = { 'start', '--always-new-process' },

  window_frame = {
    font_size = 9,
  },

  -- default_cursor_style = "BlinkingBar",
  default_cursor_style = 'BlinkingUnderline',
  visual_bell = {
    fade_in_function = 'Linear',
    fade_in_duration_ms = 150,
    fade_out_function = 'EaseOut',
    fade_out_duration_ms = 150,
  },

  window_padding = {
    top = "1cell",
    right = "1cell",
    bottom = "1cell",
    left = "1cell",
  },
  inactive_pane_hsb = {
    saturation = 0.9,
    brightness = 0.8,
  },

  font = wezterm.font 'Monaspice HuHanMe NF',
  font_size = 10,
  cursor_thickness = '8px',
  cursor_blink_rate = 800,
  anti_alias_custom_block_glyphs = true,
  command_palette_bg_color = "#0000FF",
  command_palette_fg_color = "rgba(0.75, 0.75, 0.75, 1.0)",
  window_background_opacity = 0.95,
  mux_enable_ssh_agent = false,

  mouse_bindings = {
    {
      action = wezterm.action.ScrollByLine(-1),
      alt_screen = false,
      event = { Down = { streak = 1, button = { WheelUp = 1 } } },
      mods = 'NONE',
    },
    {
      action = wezterm.action.ScrollByLine(1),
      alt_screen = false,
      event = { Down = { streak = 1, button = { WheelDown = 1 } } },
      mods = 'NONE',
    },
  },
  keys = {
    {
      key = "I",
      mods = "CTRL",
      action = wezterm.action.PaneSelect({
        show_pane_ids = true,
      }),
    },
    {
      key = "N",
      mods = "CTRL",
      action = wezterm.action.PaneSelect({
        mode = "MoveToNewWindow",
      }),
    },
  }
})

return config
