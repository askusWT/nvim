return {
  {
    "opencode.nvim",
    auto_enable = true,
    lazy = false,
    after = function()
      vim.o.autoread = true

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

      -- opencode-web.service runs persistently on port 3742; bypass pgrep discovery
      vim.g.opencode_opts = {
        server = {
          url = "http://127.0.0.1:3742",
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

      -- TUI + HTTP server on fixed port; snacks keeps process alive when window hidden
      local opencode_cmd = 'opencode --port 3742'
      local snacks_terminal_opts = { win = { position = 'right', enter = false } }

      local function oc_toggle()
        require('snacks.terminal').toggle(opencode_cmd, snacks_terminal_opts)
      end

      -- auto-show panel on any prompt submit so the response is immediately visible
      vim.api.nvim_create_autocmd('User', {
        pattern = 'OpencodeEvent:tui.command.execute',
        callback = function(args)
          local event = args.data and args.data.event
          if event and event.properties and event.properties.command == 'prompt.submit' then
            local term = require('snacks.terminal').get(opencode_cmd, { create = false })
            if term then term:show() end
          end
        end,
      })

      -- start the TUI at launch so :3742 is ready; hide immediately after creation
      vim.api.nvim_create_autocmd('VimEnter', {
        once = true,
        callback = function()
          vim.schedule(function()
            local term = require('snacks.terminal').get(opencode_cmd, snacks_terminal_opts)
            if term then
              vim.schedule(function() term:hide() end)
            end
          end)
        end,
      })

      vim.keymap.set('n',          '<leader>ot', oc_toggle,                                               { desc = 'Toggle panel' })
      vim.keymap.set({ 'n', 'x' }, '<leader>oa', function() oc.ask('@this: ') end,                       { desc = 'Ask' })
      vim.keymap.set('n',          '<leader>ob', function() oc.ask('@buffers ') end,                      { desc = 'Ask with all buffers' })
      vim.keymap.set({ 'n', 'x' }, '<leader>oc', function() oc.select() end,                             { desc = 'Commands' })
      vim.keymap.set('n', '<leader>od', function()
        local diags = vim.diagnostic.get(0)
        if #diags == 0 then
          vim.notify('No diagnostics in current buffer', vim.log.levels.INFO)
          return
        end
        local lines = {}
        for _, d in ipairs(diags) do
          table.insert(lines, string.format('line %d: [%s] %s', d.lnum + 1, d.source or '?', d.message))
        end
        oc.prompt('@this Explain these diagnostics:\n' .. table.concat(lines, '\n'))
      end, { desc = 'Explain diagnostics' })
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

      local subcmds = { 'toggle', 'ask', 'prompt', 'commands', 'stop' }
      vim.api.nvim_create_user_command('Opencode', function(opts)
        local arg = opts.args
        if arg == '' or arg == 'toggle' then
          oc_toggle()
        elseif arg == 'ask' then
          oc.ask()
        elseif arg == 'commands' then
          oc.select()
        elseif arg == 'stop' then
          pcall(require('snacks.terminal').toggle, opencode_cmd, snacks_terminal_opts)
        else
          oc.prompt('@nvim ' .. arg)
        end
      end, { nargs = '?', complete = function() return subcmds end, desc = 'Opencode commands' })
    end,
  },
}
