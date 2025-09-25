local M = {}

-- Import NUI components
local Popup = require("nui.popup")

-- Get the plugin directory path
local function get_plugin_dir()
  local config_dir = vim.fn.stdpath("config")
  return config_dir .. "/lua/plugins"
end

-- Read file content
local function read_file(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return nil
  end
  local content = file:read("*all")
  file:close()
  return content
end

-- Scan directory for plugin files
local function scan_plugin_dir()
  local plugin_dir = get_plugin_dir()
  local plugins = {}
  
  -- Use vim.fn.glob to find all .lua files
  local files = vim.fn.glob(plugin_dir .. "/*.lua", false, true)
  
  for _, file in ipairs(files) do
    table.insert(plugins, file)
  end
  
  return plugins
end

-- Extract plugin information
local function extract_plugin_info(content, filepath)
  local info = {
    file = filepath,
    name = "Unknown",
    vscode_enabled = nil,
    enabled = true
  }
  
  -- Extract plugin name from the first string in the return statement
  local name_match = content:match('return%s*{%s*["\']([^"\']+)["\']')
  if name_match then
    info.name = name_match
  else
    -- Fallback 1: explicit name field
    local field_name = content:match('name%s*=%s*["\']([^"\']+)["\']')
    if field_name then
      info.name = field_name
    else
      -- Fallback 2: first repo-like string anywhere
      local repo_like = content:match('["\']([%w_.-]+/[%w_.-]+)["\']')
      if repo_like then
        info.name = repo_like
      else
        -- Fallback 3: filename without extension
        info.name = vim.fn.fnamemodify(filepath, ":t:r")
      end
    end
  end
  
  -- Check for vscode = true/false
  local vscode_match = content:match('vscode%s*=%s*(%w+)')
  if vscode_match then
    info.vscode_enabled = vscode_match == "true"
  end
  
  -- Check for enabled = false
  local enabled_match = content:match('enabled%s*=%s*(%w+)')
  if enabled_match then
    info.enabled = enabled_match == "true"
  end
  
  return info
end

-- Analyze plugins
local function analyze_plugins()
  local plugins = scan_plugin_dir()
  local vscode_enabled = {}
  local vscode_disabled = {}
  local no_vscode_info = {}
  local disabled_plugins = {}
  
  for _, file in ipairs(plugins) do
    local content = read_file(file)
    if content then
      local info = extract_plugin_info(content, file)
      
      if not info.enabled then
        table.insert(disabled_plugins, info)
      elseif info.vscode_enabled == true then
        table.insert(vscode_enabled, info)
      elseif info.vscode_enabled == false then
        table.insert(vscode_disabled, info)
      else
        table.insert(no_vscode_info, info)
      end
    end
  end
  
  -- Sort by plugin name
  local function sort_by_name(a, b)
    return a.name < b.name
  end
  
  table.sort(vscode_enabled, sort_by_name)
  table.sort(vscode_disabled, sort_by_name)
  table.sort(no_vscode_info, sort_by_name)
  table.sort(disabled_plugins, sort_by_name)
  
  return {
    total = #plugins,
    vscode_enabled = vscode_enabled,
    vscode_disabled = vscode_disabled,
    no_vscode_info = no_vscode_info,
    disabled_plugins = disabled_plugins
  }
end

-- Create NUI popup with formatted content
local function create_popup(title, content_lines)
  local popup = Popup({
    position = "50%",
    enter = true,
    size = {
      width = "80%",
      height = "80%",
    },
    border = {
      style = "rounded",
      text = {
        top = " " .. title .. " ",
        top_align = "center",
      },
    },
    buf_options = {
      modifiable = true,
      readonly = false,
    },
    win_options = {
      wrap = true,
      number = false,
      relativenumber = false,
      cursorline = true,
    },
  })

  -- Mount the popup
  popup:mount()

  -- Ensure focus on the popup window
  if popup.winid and vim.api.nvim_win_is_valid(popup.winid) then
    vim.api.nvim_set_current_win(popup.winid)
  end

  -- Set the content
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, content_lines)

  -- Make buffer readonly after setting content
  vim.api.nvim_buf_set_option(popup.bufnr, "modifiable", false)
  vim.api.nvim_buf_set_option(popup.bufnr, "readonly", true)

  -- Set filetype for syntax highlighting
  vim.api.nvim_buf_set_option(popup.bufnr, "filetype", "markdown")

  -- Add keymaps for better UX
  vim.keymap.set("n", "q", function()
    popup:unmount()
  end, { buffer = popup.bufnr, desc = "Close popup" })

  vim.keymap.set("n", "<Esc>", function()
    popup:unmount()
  end, { buffer = popup.bufnr, desc = "Close popup" })

  return popup
end

-- Format content lines with proper styling
local function format_content_lines(results, title)
  local lines = {}
  local function push(s)
    lines[#lines + 1] = s
  end

  local function section(heading, items)
    local count = #items
    if count == 0 then
      return
    end
    push(string.format("## %s (%d)", heading, count))
    for i = 1, count do
      push("  • " .. items[i].name)
    end
    push("")
  end

  -- Header
  push("# " .. title)
  push("")

  -- Sections (only enabled and explicitly disabled)
  section("Enabled for VSCode", results.vscode_enabled)
  section("Explicitly Disabled for VSCode", results.vscode_disabled)

  -- Not enabled for VSCode (missing `vscode = true`)
  local not_enabled = results.no_vscode_info or {}
  if #not_enabled > 0 then
    push(string.format("## Not enabled for VSCode (%d)", #not_enabled))
    for i = 1, #not_enabled do
      push("  • " .. not_enabled[i].name)
    end
    push("")
    push("Tip: add `vscode = true` in the plugin spec to enable.")
    push("")
  end

  push("Press 'q' or 'Esc' to close")

  return lines
end

-- Main command function
function M.show_status()
  local results = analyze_plugins()
  local content_lines = format_content_lines(results, "VSCode Plugin Status")
  create_popup("VSCode Plugin Status", content_lines)
end

-- Summary command function
function M.show_summary()
  local results = analyze_plugins()
  local lines = {}
  
  table.insert(lines, "📊 VSCode Plugins Summary")
  table.insert(lines, "================================")
  table.insert(lines, "")
  table.insert(lines, string.format("✅ VSCode enabled: %d", #results.vscode_enabled))
  table.insert(lines, string.format("❌ VSCode disabled: %d", #results.vscode_disabled))
  table.insert(lines, string.format("❓ No VSCode info: %d", #results.no_vscode_info))
  table.insert(lines, string.format("🚫 Plugin disabled: %d", #results.disabled_plugins))
  table.insert(lines, "")
  
  if #results.vscode_enabled > 0 then
    table.insert(lines, "✅ PLUGINS ENABLED FOR VSCODE:")
    table.insert(lines, string.rep("-", 40))
    for _, plugin in ipairs(results.vscode_enabled) do
      table.insert(lines, string.format("  • %s", plugin.name))
    end
  end
  
  table.insert(lines, "")
  table.insert(lines, "Press 'q' or 'Esc' to close")
  
  create_popup("VSCode Plugins Summary", lines)
end

-- Candidates command function
function M.show_not_enabled()
  local results = analyze_plugins()
  local lines = {}
  
  table.insert(lines, "🔍 Plugins Not Enabled for VSCode")
  table.insert(lines, "========================================")
  table.insert(lines, "These plugins may work in VSCode but aren't explicitly tested.")
  table.insert(lines, "Consider adding 'vscode = true' to plugins you want to use in VSCode.")
  table.insert(lines, "")
  
  if #results.no_vscode_info > 0 then
    for _, plugin in ipairs(results.no_vscode_info) do
      table.insert(lines, string.format("  • %s", plugin.name))
    end
  end
  
  table.insert(lines, "")
  table.insert(lines, "💡 To enable a plugin for VSCode:")
  table.insert(lines, "   1. Open the plugin file in nvim/lua/plugins/")
  table.insert(lines, "   2. Add 'vscode = true,' after the plugin name")
  table.insert(lines, "   3. Example:")
  table.insert(lines, "      return {")
  table.insert(lines, "        \"plugin-name\",")
  table.insert(lines, "        vscode = true,  ← Add this line")
  table.insert(lines, "        -- other config...")
  table.insert(lines, "      }")
  table.insert(lines, "")
  table.insert(lines, "Press 'q' or 'Esc' to close")
  
  create_popup("VSCode Plugins Not Enabled", lines)
end

-- Create commands
-- Command registrations are handled in plugin/vscode-compat.lua

return M