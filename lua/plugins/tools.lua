return {
  {
    "opencode.nvim",
    auto_enable = true,
    lazy = false,
    after = function()
      local opencode_cmd = 'opencode --port'
      local snacks_terminal_opts = {
        win = {
          position = 'right',
          enter = false,
          on_win = function(win)
            require('opencode.terminal').setup(win.win)
          end,
        },
      }
      local function nvim_ctx()
        local buf = vim.api.nvim_get_current_buf()
        return string.format(
          'Editor: Neovim %d.%d | File: %s | ft: %s | cwd: %s',
          vim.version().major, vim.version().minor,
          vim.api.nvim_buf_get_name(buf),
          vim.bo[buf].filetype,
          vim.fn.getcwd()
        )
      end
      vim.g.opencode_opts = {
        server = {
          start = function()
            require('snacks.terminal').open(opencode_cmd, snacks_terminal_opts)
          end,
          stop = function()
            require('snacks.terminal').get(opencode_cmd, snacks_terminal_opts):close()
          end,
          toggle = function()
            require('snacks.terminal').toggle(opencode_cmd, snacks_terminal_opts)
          end,
        },
        contexts = {
          nvim = nvim_ctx,
        },
      }
      local oc = require("opencode")
      local function oc_toggle()
        require('snacks.terminal').toggle(opencode_cmd, snacks_terminal_opts)
      end
      local function oc_stop()
        local term = require('snacks.terminal').get(opencode_cmd, snacks_terminal_opts)
        if term then term:close() end
      end
      vim.keymap.set('n', '<leader>ot', oc_toggle,                                             { desc = 'Toggle panel' })
      vim.keymap.set('n', '<leader>oa', oc.ask,                                                { desc = 'Ask' })
      vim.keymap.set('n', '<leader>ob', function() oc.prompt('@buffers') end,                  { desc = 'Share all buffers' })
      vim.keymap.set('n', '<leader>os', oc.select,                                             { desc = 'Select' })
      vim.keymap.set('n', '<leader>od', function() oc.prompt('@nvim diagnostics') end,         { desc = 'Explain diagnostics' })
      -- operator maps: work with motions (e.g. <leader>oeip) AND visual selection
      vim.keymap.set('n', '<leader>oe', function() return oc.operator('@nvim explain') end,    { expr = true, desc = 'Explain (operator)' })
      vim.keymap.set('x', '<leader>oe', function() oc.prompt('@nvim explain') end,             { desc = 'Explain selection' })
      vim.keymap.set('n', '<leader>of', function() return oc.operator('@nvim fix') end,        { expr = true, desc = 'Fix (operator)' })
      vim.keymap.set('x', '<leader>of', function() oc.prompt('@nvim fix') end,                 { desc = 'Fix selection' })
      vim.keymap.set('n', '<leader>oR', function() return oc.operator('@nvim review') end,     { expr = true, desc = 'Review (operator)' })
      vim.keymap.set('x', '<leader>oR', function() oc.prompt('@nvim review') end,              { desc = 'Review selection' })
      local subcmds = { 'toggle', 'ask', 'prompt', 'select', 'start', 'stop' }
      vim.api.nvim_create_user_command('Opencode', function(opts)
        local arg = opts.args
        if arg == '' or arg == 'toggle' then
          oc_toggle()
        elseif arg == 'ask' then
          oc.ask()
        elseif arg == 'select' then
          oc.select()
        elseif arg == 'start' then
          oc.start()
        elseif arg == 'stop' then
          oc_stop()
        else
          -- treat as a prompt string; inject @nvim context automatically
          oc.prompt('@nvim ' .. arg)
        end
      end, { nargs = '?', complete = function() return subcmds end, desc = 'Opencode commands' })
    end,
  },
}
