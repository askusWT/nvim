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
    cmd = { "FidgetHistory", "FidgetClear" },
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
    cmd = { "FineCmdline" },
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
    cmd = { "WhichKey" },
    event = "DeferredUIEnter",
    after = function(plugin)
      require('which-key').setup({ show_help = false, show_keys = false })
      -- Uppercase proxies: pressing <leader>W etc. re-fires the lowercase group
      local function proxy(lhs)
        return function()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, true, true), 'i', false)
        end
      end
      require('which-key').add {
        { '<leader>B', proxy('<leader>b'), hidden = true },
        { '<leader>C', proxy('<leader>c'), hidden = true },
        { '<leader>D', proxy('<leader>d'), hidden = true },
        { '<leader>F', proxy('<leader>f'), hidden = true },
        { '<leader>G', proxy('<leader>g'), hidden = true },
        { '<leader>M', proxy('<leader>m'), hidden = true },
        { '<leader>O', proxy('<leader>o'), hidden = true },
        { '<leader>R', proxy('<leader>r'), hidden = true },
        { '<leader>S', proxy('<leader>s'), hidden = true },
        { '<leader>U', proxy('<leader>u'), hidden = true },
        { '<leader>W', proxy('<leader>w'), hidden = true },
        { '<leader>X', proxy('<leader>x'), hidden = true },
      }
      require('which-key').add {
        { "<leader><leader>",  group = "Buffers" },
        { "<leader><leader>_", hidden = true },
        { "<leader>b",         group = "Buffers" },
        { "<leader>b_",        hidden = true },
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
        { "<leader>u",         group = "Toggles" },
        { "<leader>ub",        desc = "Toggle git blame" },
        { "<leader>ud",        desc = "Toggle diagnostics" },
        { "<leader>uw",        desc = "Toggle word wrap" },
        { "<leader>u_",        hidden = true },
        { "<leader>w",         group = "Workspace" },
        { "<leader>w_",        hidden = true },
        { "<leader>x",         group = "Lists" },
        { "<leader>x_",        hidden = true },
      }

      -- THIS CODE IS UNVERIFIED
      -- Toggles (<leader>u = LazyVim convention)
      vim.keymap.set('n', '<leader>ub', function() require('gitsigns').toggle_current_line_blame() end, { desc = 'Toggle git blame' })
      vim.keymap.set('n', '<leader>ud', function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end, { desc = 'Toggle diagnostics' })
      vim.keymap.set('n', '<leader>uw', function() vim.o.wrap = not vim.o.wrap end, { desc = 'Toggle word wrap' })
      -- Diagnostic navigation
      vim.keymap.set('n', ']d', function() vim.diagnostic.goto_next() end, { desc = 'Next Diagnostic' })
      vim.keymap.set('n', '[d', function() vim.diagnostic.goto_prev() end, { desc = 'Prev Diagnostic' })
      vim.keymap.set('n', ']e', function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR }) end, { desc = 'Next Error' })
      vim.keymap.set('n', '[e', function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR }) end, { desc = 'Prev Error' })
      vim.keymap.set('n', ']w', function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN }) end, { desc = 'Next Warning' })
      vim.keymap.set('n', '[w', function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN }) end, { desc = 'Prev Warning' })
      -- Window splits and navigation
      vim.keymap.set('n', '<leader>-',  '<cmd>split<cr>',  { desc = 'Split Window Horizontal' })
      vim.keymap.set('n', '<leader>|',  '<cmd>vsplit<cr>', { desc = 'Split Window Vertical' })
      vim.keymap.set('n', '<leader>wd', '<cmd>close<cr>',  { desc = 'Delete Window' })
      vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Window Left' })
      vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Window Down' })
      vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Window Right' })
    end,
  },
}
