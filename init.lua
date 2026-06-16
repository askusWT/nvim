-- Modular nvim config entry point.
-- Load order matters:
--   1. bootstrap  — nixInfo global, lze handlers, clipboard provider
--   2. settings   — leader keys (must precede plugins), vim.o options, autocmds
--   3. keymaps    — motion, window, diagnostic, clipboard keymaps
--   4. lze.load   — plugin specs via import; handlers already registered above
--
-- See lua/config/health.lua for runtime checks: :checkhealth config
-- See scripts/check.sh for headless smoke test

require('bootstrap')
require('settings')
require('keymaps')

-- NOTE: lze.load can be called multiple times.
-- Each plugin file returns a flat table of lze specs.
-- https://github.com/BirdeeHub/lze?tab=readme-ov-file#structuring-your-plugins
nixInfo.lze.load {
  { import = 'plugins.colorscheme' },
  { import = 'plugins.snacks' },
  { import = 'plugins.lsp' },
  { import = 'plugins.treesitter' },
  { import = 'plugins.format' },
  { import = 'plugins.completion' },
  { import = 'plugins.ui' },
  { import = 'plugins.git' },
  { import = 'plugins.editing' },
  { import = 'plugins.tools' },
  { import = 'plugins.telescope' },
}
