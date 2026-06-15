vim.loader.enable()

do
  -- Set up a global in a way that also handles non-nix compat
  local ok
  ok, _G.nixInfo = pcall(require, vim.g.nix_info_plugin_name)
  if not ok then
    package.loaded[vim.g.nix_info_plugin_name] = setmetatable({}, {
      __call = function(_, default) return default end
    })
    _G.nixInfo = require(vim.g.nix_info_plugin_name)
    -- If you always use the fetcher function to fetch nix values,
    -- rather than indexing into the tables directly,
    -- it will use the value you specified as the default
    -- TODO: for non-nix compat, vim.pack.add in another file and require here.
  end
  nixInfo.isNix = vim.g.nix_info_plugin_name ~= nil
  ---@module 'lzextras'
  ---@type lzextras | lze
  nixInfo.lze = setmetatable(require('lze'), getmetatable(require('lzextras')))
  function nixInfo.get_nix_plugin_path(name)
    return nixInfo(nil, "plugins", "lazy", name) or nixInfo(nil, "plugins", "start", name)
  end
end

-- NOTE: handlers must register before lze.load; order matters:
-- auto_enable and for_cat must come before the lsp handler
nixInfo.lze.register_handlers {
  {
    -- adds an `auto_enable` field to lze specs
    -- if true, will disable it if not installed by nix.
    -- if string, will disable if that name was not installed by nix.
    -- if a table of strings, it will disable if any were not.
    spec_field = "auto_enable",
    set_lazy = false,
    modify = function(plugin)
      if vim.g.nix_info_plugin_name then
        if type(plugin.auto_enable) == "table" then
          for _, name in pairs(plugin.auto_enable) do
            if not nixInfo.get_nix_plugin_path(name) then
              plugin.enabled = false
              break
            end
          end
        elseif type(plugin.auto_enable) == "string" then
          if not nixInfo.get_nix_plugin_path(plugin.auto_enable) then
            plugin.enabled = false
          end
        elseif type(plugin.auto_enable) == "boolean" and plugin.auto_enable then
          if not nixInfo.get_nix_plugin_path(plugin.name) then
            plugin.enabled = false
          end
        end
      end
      return plugin
    end,
  },
  {
    -- we made an options.settings.cats with the value of enable for our top level specs
    -- give for_cat = "name" to disable if that one is not enabled
    spec_field = "for_cat",
    set_lazy = false,
    modify = function(plugin)
      if vim.g.nix_info_plugin_name then
        if type(plugin.for_cat) == "string" then
          plugin.enabled = nixInfo(false, "settings", "cats", plugin.for_cat)
        end
      end
      return plugin
    end,
  },
  -- From lzextras. Makes it so you can set up lsps within lze specs,
  -- triggering lspconfig setup hooks only on the correct filetypes.
  -- Must register after auto_enable/for_cat (relies on modify hook + enabled value).
  nixInfo.lze.lsp,
}

-- NOTE: This config uses lzextras.lsp handler
-- https://github.com/BirdeeHub/lzextras?tab=readme-ov-file#lsp-handler
-- Because we have the paths, we can set a more performant fallback function
-- for when you don't provide a filetype to trigger on yourself.
nixInfo.lze.h.lsp.set_ft_fallback(function(name)
  local lspcfg = nixInfo.get_nix_plugin_path "nvim-lspconfig"
  if lspcfg then
    local ok, cfg = pcall(dofile, lspcfg .. "/lsp/" .. name .. ".lua")
    return (ok and cfg or {}).filetypes or {}
  else
    -- the less performant thing we are trying to avoid at startup
    return (vim.lsp.config[name] or {}).filetypes or {}
  end
end)

-- Crostini clipboard: OSC 52 write works via Zellij; read does not (Zellij unimplemented).
-- xclip does NOT reach ChromeOS clipboard (sommelier doesn't bridge it).
-- To paste FROM ChromeOS into nvim: use Ctrl+Shift+V in insert mode (terminal paste).
vim.g.clipboard = {
  name = 'OSC52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = function() return {} end,
    ['*'] = function() return {} end,
  },
}
