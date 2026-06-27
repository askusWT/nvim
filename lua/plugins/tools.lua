return {
  {
    "opencode.nvim",
    auto_enable = true,
    lazy = false,
    after = function()
      vim.o.autoread = true

      local opencode_cmd = 'opencode --port'
      local snacks_terminal_opts = {
        win = {
          position = 'right',
          enter = false,
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

      -- server.start is a simple function: safe to put in vim.g (README pattern)
      -- snacks picker actions have mixed-type keys and must go via config.opts directly
      vim.g.opencode_opts = {
        server = {
          start = function()
            require('snacks.terminal').open(opencode_cmd, snacks_terminal_opts)
          end,
        },
        events = {
          reload = true,
          permissions = {
            enabled = true,
            edits = { enabled = true },
          },
        },
      }

      local oc = require("opencode")
      -- builtins (@this, @buffers, @diagnostics etc.) come from defaults
      require("opencode.config").opts.contexts["@nvim"] = nvim_ctx

      local function oc_toggle()
        require('snacks.terminal').toggle(opencode_cmd, snacks_terminal_opts)
      end

      -- auto-show panel when prompt is submitted
      vim.api.nvim_create_autocmd('User', {
        pattern = 'OpencodeEvent:tui.command.execute',
        callback = function(args)
          local event = args.data.event
          if event.properties.command == 'prompt.submit' then
            local win = require('snacks.terminal').get(opencode_cmd, { create = false })
            if win then win:show() end
          end
        end,
      })

      vim.keymap.set('n',          '<leader>ot', oc_toggle,                                               { desc = 'Toggle panel' })
      vim.keymap.set({ 'n', 'x' }, '<leader>oa', function() oc.ask('@this: ') end,                       { desc = 'Ask' })
      vim.keymap.set('n',          '<leader>ob', function() oc.ask('@buffers ') end,                      { desc = 'Ask with all buffers' })
      vim.keymap.set({ 'n', 'x' }, '<leader>os', function() oc.select() end,                             { desc = 'Select' })
      vim.keymap.set('n',          '<leader>od', function() oc.prompt('@nvim diagnostics') end,           { desc = 'Explain diagnostics' })
      vim.keymap.set('n',          '<leader>oe', function() return oc.operator('@nvim explain') end,      { expr = true, desc = 'Explain (operator)' })
      vim.keymap.set('x',          '<leader>oe', function() oc.prompt('@nvim explain') end,               { desc = 'Explain selection' })
      vim.keymap.set('n',          '<leader>of', function() return oc.operator('@nvim fix') end,          { expr = true, desc = 'Fix (operator)' })
      vim.keymap.set('x',          '<leader>of', function() oc.prompt('@nvim fix') end,                   { desc = 'Fix selection' })
      vim.keymap.set('n',          '<leader>oR', function() return oc.operator('@nvim review') end,       { expr = true, desc = 'Review (operator)' })
      vim.keymap.set('x',          '<leader>oR', function() oc.prompt('@nvim review') end,                { desc = 'Review selection' })
      vim.keymap.set({ 'n', 'x' }, 'go',         function() return oc.operator('@this ') end,             { expr = true, desc = 'Append range to OpenCode' })
      vim.keymap.set('n',          'goo',         function() return oc.operator('@this ') .. '_' end,     { expr = true, desc = 'Append line to OpenCode' })
      vim.keymap.set('n',          '<S-C-u>',    function() oc.command('session.half.page.up') end,      { desc = 'Scroll OpenCode up' })
      vim.keymap.set('n',          '<S-C-d>',    function() oc.command('session.half.page.down') end,    { desc = 'Scroll OpenCode down' })

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
          pcall(require('snacks.terminal').toggle, opencode_cmd, snacks_terminal_opts)
        else
          oc.prompt('@nvim ' .. arg)
        end
      end, { nargs = '?', complete = function() return subcmds end, desc = 'Opencode commands' })
    end,
  },
}
