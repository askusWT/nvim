-- :checkhealth config
local M = {}

function M.check()
  vim.health.start("nvim-config")

  -- 1. Bootstrap: nixInfo global
  if _G.nixInfo then
    vim.health.ok("nixInfo global is set up")
    if type(nixInfo.lze) == "table" then
      vim.health.ok("nixInfo.lze is configured")
    else
      vim.health.error("nixInfo.lze is missing or not a table")
    end
    if nixInfo.isNix ~= nil then
      vim.health.ok("nixInfo.isNix = " .. tostring(nixInfo.isNix))
    else
      vim.health.warn("nixInfo.isNix not set")
    end
    if type(nixInfo.get_nix_plugin_path) == "function" then
      vim.health.ok("nixInfo.get_nix_plugin_path is available")
    else
      vim.health.error("nixInfo.get_nix_plugin_path is missing")
    end
  else
    vim.health.error("nixInfo global is missing — bootstrap.lua may not have loaded")
  end

  -- 2. lazygit_fix (set in snacks after-hook; only available post-startup)
  if _G.nixInfo and type(nixInfo.lazygit_fix) == "function" then
    vim.health.ok("nixInfo.lazygit_fix is defined (snacks loaded successfully)")
  else
    vim.health.warn("nixInfo.lazygit_fix not yet defined — snacks may not have loaded yet")
  end

  -- 3. Leader keys
  if vim.g.mapleader == ' ' then
    vim.health.ok("mapleader is set to <Space>")
  else
    vim.health.warn("mapleader is '" .. tostring(vim.g.mapleader) .. "' (expected <Space>)")
  end

  -- 4. Module load checks
  vim.health.start("nvim-config: module integrity")
  local modules = {
    'bootstrap',
    'settings',
    'keymaps',
    'plugins.colorscheme',
    'plugins.snacks',
    'plugins.lsp',
    'plugins.treesitter',
    'plugins.format',
    'plugins.completion',
    'plugins.ui',
    'plugins.git',
    'plugins.editing',
    'plugins.tools',
  }
  for _, mod in ipairs(modules) do
    -- Use package.loaded to check if modules ran without re-requiring them
    if package.loaded[mod] ~= nil then
      vim.health.ok(mod .. " loaded")
    else
      -- Try loading it now (safe for non-side-effectful modules)
      local ok, err = pcall(require, mod)
      if ok then
        vim.health.ok(mod .. " loads OK (was not yet required)")
      else
        vim.health.error(mod .. " FAILED to load: " .. tostring(err))
      end
    end
  end

  -- 5. Key plugins in package.loaded
  vim.health.start("nvim-config: plugin load state")
  local lazy_plugins = { 'snacks', 'lualine', 'gitsigns', 'blink.cmp', 'which-key', 'conform' }
  for _, p in ipairs(lazy_plugins) do
    if package.loaded[p] then
      vim.health.ok(p .. " is loaded")
    else
      vim.health.info(p .. " not yet loaded (may be lazy — trigger its filetype/event)")
    end
  end

  -- 6. LSP handler registration
  vim.health.start("nvim-config: LSP")
  local lsp_clients = vim.lsp.get_clients()
  if #lsp_clients > 0 then
    for _, client in ipairs(lsp_clients) do
      vim.health.ok("LSP client active: " .. client.name)
    end
  else
    vim.health.info("No LSP clients active (open a file to trigger them)")
  end
end

return M
