return {
  {
    "vim-startuptime",
    auto_enable = true,
    cmd = { "StartupTime" },
    before = function(_)
      vim.g.startuptime_event_width = 0
      vim.g.startuptime_tries = 10
      vim.g.startuptime_exe_path = nixInfo(vim.v.progpath, "progpath")
    end,
  },
  {
    "fidget.nvim",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function(plugin)
      require('fidget').setup({})
    end,
  },
  {
    "lualine.nvim",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function(plugin)
      require('lualine').setup({
        options = {
          icons_enabled = true,
          theme = 'auto',
          component_separators = '|',
          section_separators = '',
        },
        sections = {
          lualine_c = {
            { 'filename', path = 1, status = true, },
          },
        },
        inactive_sections = {
          lualine_b = {
            { 'filename', path = 3, status = true, },
          },
          lualine_x = {'filetype'},
        },
        tabline = {
          lualine_a = { 'buffers' },
          lualine_z = { 'tabs' }
        },
      })
    end,
  },
  -- THIS CODE IS UNVERIFIED
  {
    "nui.nvim",
    auto_enable = true,
    dep_of = { "fine-cmdline.nvim" },
  },
  {
    "fine-cmdline.nvim",
    auto_enable = true,
    event = "VimEnter",
    after = function(_)
      local fine = require('fine-cmdline')
      fine.setup({
        cmdline = { enable_keymaps = true, smart_history = false },
        popup   = { position = { row = '30%', col = '50%' }, size = { width = '60%' } },
      })
      vim.api.nvim_set_keymap('n', ':', '<cmd>FineCmdline<CR>', { noremap = true })
    end,
  },
  {
    "dressing.nvim",
    auto_enable = true,
    event = "VimEnter",
    after = function(_)
      require('dressing').setup({
        input  = { enabled = false }, -- snacks.input handles vim.ui.input
        select = { enabled = true },
      })
    end,
  },
  {
    "which-key.nvim",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function(plugin)
      require('which-key').setup({ show_help = false, show_keys = false })
      require('which-key').add {
        { "<leader><leader>",  group = "Buffers" },
        { "<leader><leader>_", hidden = true },
        { "<leader>c",         group = "Code" },
        { "<leader>c_",        hidden = true },
        { "<leader>d",         group = "Document" },
        { "<leader>d_",        hidden = true },
        { "<leader>f",         group = "Find Files" },
        { "<leader>f_",        hidden = true },
        { "<leader>g",         group = "Git" },
        { "<leader>gg",        desc = "LazyGit" },
        { "<leader>g_",        hidden = true },
        { "<leader>m",         group = "Markdown" },
        { "<leader>o",         group = "Opencode" },
        { "<leader>o_",        hidden = true },
        { "<leader>m_",        hidden = true },
        { "<leader>r",         group = "Rename" },
        { "<leader>r_",        hidden = true },
        { "<leader>s",         group = "Search" },
        { "<leader>s_",        hidden = true },
        { "<leader>t",         group = "Toggles" },
        { "<leader>tb",        desc = "Toggle git blame" },
        { "<leader>td",        desc = "Toggle diagnostics" },
        { "<leader>tw",        desc = "Toggle word wrap" },
        { "<leader>t_",        hidden = true },
        { "<leader>w",         group = "Workspace" },
        { "<leader>w_",        hidden = true },
      }

      -- Toggles
      vim.keymap.set('n', '<leader>tb', function() require('gitsigns').toggle_current_line_blame() end, { desc = 'Toggle git blame' })
      vim.keymap.set('n', '<leader>td', function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end, { desc = 'Toggle diagnostics' })
      vim.keymap.set('n', '<leader>tw', function() vim.o.wrap = not vim.o.wrap end, { desc = 'Toggle word wrap' })
    end,
  },
}
