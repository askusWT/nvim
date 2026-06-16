return {
  {
    "snacks.nvim",
    auto_enable = true,
    -- snacks makes a global, and then lazily loads itself
    lazy = false,
    -- priority only affects startup plugins
    priority = 1000,
    after = function(plugin)
      vim.api.nvim_set_hl(0, "MySnacksIndent", { fg = "#32a88f" })
      require('snacks').setup({
        explorer = { replace_netrw = true, },
        input = {},
        notifier = {},
        quickfile = {},
        scroll = {
          animate = {
            duration = { step = 15, total = 250 },
            easing = "linear",
          },
        },
        words = {},
        picker = {
          sources = {
            explorer = {
              auto_close = true,
            },
          },
        },
        git = {},
        terminal = {},
        dashboard = {
          enabled = true,
          width = 60,
          preset = {
            header = [[
  ██╗  ██╗██╗   ██╗██╗███╗   ███╗
  ███╗ ██║██║   ██║██║████╗ ████║
  ██╔██╗██║╚██╗██╔╝██║██╔████╔██║
  ██║╚████║ ╚███╔╝ ██║██║╚██╔╝██║
  ██║ ╚███║  ╚█╔╝  ██║██║ ╚═╝ ██║
  ╚═╝  ╚══╝   ╚╝   ╚═╝╚═╝     ╚═╝]],
            keys = {
              { icon = " ", key = "f", desc = "Find File",     action = ":lua Snacks.dashboard.pick('files')" },
              { icon = " ", key = "n", desc = "New File",      action = ":ene | startinsert" },
              { icon = " ", key = "g", desc = "Live Grep",     action = ":lua Snacks.dashboard.pick('live_grep')" },
              { icon = " ", key = "r", desc = "Recent Files",  action = ":lua Snacks.dashboard.pick('oldfiles')" },
              { icon = " ", key = "v", desc = "Visited Files", action = ":VisitedFiles" },
              { icon = " ", key = "s", desc = "Session",       section = "session" },
              { icon = " ", key = "q", desc = "Quit",          action = ":qa" },
            },
          },
          sections = {
            { section = "header" },
            { section = "keys",         gap = 1, padding = 1 },
            { section = "recent_files", title = "Recent", limit = 5, padding = 1 },
            { section = "startup" },
          },
        },
        scope = {},
        indent = {
          scope = {
            hl = 'MySnacksIndent',
          },
          chunk = {
            hl = 'MySnacksIndent',
          }
        },
        statuscolumn = {
          left = { "mark", "git" },
          right = { "sign", "fold" },
          folds = {
            open = false,
            git_hl = false,
          },
          git = {
            patterns = { "GitSign", "MiniDiffSign" },
          },
          refresh = 50,
        },
        -- make sure lazygit always reopens the correct program
        -- hopefully this can be removed one day
        lazygit = {
          config = {
            os = {
              editPreset = "nvim-remote",
              edit = vim.v.progpath .. [=[ --server "$NVIM" --remote-send '<cmd>lua nixInfo.lazygit_fix({{filename}})<CR>']=],
              editAtLine = vim.v.progpath .. [=[ --server "$NVIM" --remote-send '<cmd>lua nixInfo.lazygit_fix({{filename}}, {{line}})<CR>']=],
              openDirInEditor = vim.v.progpath .. [=[ --server "$NVIM" --remote-send '<cmd>lua nixInfo.lazygit_fix({{dir}})<CR>']=],
              -- this one isnt a remote command, make sure it gets our config regardless of if we name it nvim or not
              editAtLineAndWait = nixInfo(vim.v.progpath, "progpath") .. " +{{line}} {{filename}}",
            },
          },
        },
      })
      -- Handle the backend of those remote commands.
      -- hopefully this can be removed one day
      -- NOTE: lazygit_fix must be defined here — it's a closure that references Snacks state
      nixInfo.lazygit_fix = function(path, line)
        local prev = vim.fn.bufnr("#")
        local prev_win = vim.fn.bufwinid(prev)
        vim.api.nvim_feedkeys("q", "n", false)
        if line then
          vim.api.nvim_buf_call(prev, function()
            vim.cmd.edit(path)
            local buf = vim.api.nvim_get_current_buf()
            vim.schedule(function()
              if buf then
                vim.api.nvim_win_set_buf(prev_win, buf)
                vim.api.nvim_win_set_cursor(0, { line or 0, 0})
              end
            end)
          end)
        else
          vim.api.nvim_buf_call(prev, function()
            vim.cmd.edit(path)
            local buf = vim.api.nvim_get_current_buf()
            vim.schedule(function()
              if buf then
                vim.api.nvim_win_set_buf(prev_win, buf)
              end
            end)
          end)
        end
      end
      vim.api.nvim_create_user_command('LazyGit',        function() Snacks.lazygit.open() end,           { desc = 'Open LazyGit' })
      vim.api.nvim_create_user_command('Explorer',       function() Snacks.explorer.open() end,          { desc = 'Open file explorer' })
      vim.api.nvim_create_user_command('Grep',           function() Snacks.picker.grep() end,            { desc = 'Grep files' })
      vim.api.nvim_create_user_command('SnacksFiles',    function() Snacks.picker.files() end,           { desc = 'Find files' })
      vim.api.nvim_create_user_command('SnacksBufLines', function() Snacks.picker.lines() end,           { desc = 'Buffer lines' })
      vim.api.nvim_create_user_command('SnacksBuffers',  function() Snacks.picker.buffers() end,         { desc = 'Open buffers' })
      vim.api.nvim_create_user_command('SnacksHelp',     function() Snacks.picker.help() end,            { desc = 'Help pages' })
      vim.api.nvim_create_user_command('SnacksMarks',    function() Snacks.picker.marks() end,           { desc = 'Marks' })
      vim.api.nvim_create_user_command('SnacksKeymaps',  function() Snacks.picker.keymaps() end,         { desc = 'Keymaps' })
      vim.api.nvim_create_user_command('SnacksDiag',     function() Snacks.picker.diagnostics() end,     { desc = 'Diagnostics' })
      vim.api.nvim_create_user_command('SnacksUndo',     function() Snacks.picker.undo() end,            { desc = 'Undo history' })
      vim.api.nvim_create_user_command('SnacksResume',   function() Snacks.picker.resume() end,          { desc = 'Resume last picker' })
      vim.api.nvim_create_user_command('SnacksNotify',   function() Snacks.notifier.show_history() end,  { desc = 'Notification history' })
      -- bufdelete / rename / gitbrowse
      -- THIS CODE IS UNVERIFIED
      vim.api.nvim_create_user_command('BufDelete', function() Snacks.bufdelete() end, { desc = 'Delete buffer (keep window)' })
      vim.api.nvim_create_user_command('GitBrowse', function() Snacks.gitbrowse() end, { desc = 'Open file in browser (GitHub etc.)' })
      vim.keymap.set('n', '<leader><leader>d', function() Snacks.bufdelete() end,      { desc = 'Delete buffer' })
      vim.keymap.set('n', '<leader>rf',        function() Snacks.rename.rename() end,  { desc = 'Rename file (LSP-aware)' })
      vim.keymap.set('n', '<leader>gB',        function() Snacks.gitbrowse() end,      { desc = 'Git browse (open in browser)' })
      -- words navigation (module already enabled above)
      vim.keymap.set('n', ']]', function() Snacks.words.jump(1) end,  { desc = 'Next word occurrence' })
      vim.keymap.set('n', '[[', function() Snacks.words.jump(-1) end, { desc = 'Prev word occurrence' })
      -- snacks isn't loaded lazily, so keybinds can be set directly here
      vim.keymap.set("n", "-", function() Snacks.explorer.open() end, { desc = 'Snacks file explorer' })
      vim.keymap.set("n", "<c-\\>", function() Snacks.terminal.open() end, { desc = 'Snacks Terminal' })
      vim.keymap.set("n", "<leader>gg", function() Snacks.lazygit.open() end, { desc = 'LazyGit' })
      vim.keymap.set('n', "<leader>sf", function() Snacks.picker.smart() end, { desc = "Smart Find Files" })
      vim.keymap.set('n', "<leader><leader>s", function() Snacks.picker.buffers() end, { desc = "Search Buffers" })
      -- grep
      vim.keymap.set('n', "<leader>sb", function() Snacks.picker.lines() end, { desc = "Buffer Lines" })
      vim.keymap.set('n', "<leader>sB", function() Snacks.picker.grep_buffers() end, { desc = "Grep Open Buffers" })
      vim.keymap.set('n', "<leader>sg", function() Snacks.picker.grep() end, { desc = "Grep" })
      vim.keymap.set({ "n", "x" }, "<leader>sw", function() Snacks.picker.grep_word() end, { desc = "Grep word/selection" })
      -- search
      vim.keymap.set('n', "<leader>sd", function() Snacks.picker.diagnostics() end, { desc = "Diagnostics" })
      vim.keymap.set('n', "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, { desc = "Buffer Diagnostics" })
      vim.keymap.set('n', "<leader>sh", function() Snacks.picker.help() end, { desc = "Help Pages" })
      vim.keymap.set('n', "<leader>sj", function() Snacks.picker.jumps() end, { desc = "Jumps" })
      vim.keymap.set('n', "<leader>sk", function() Snacks.picker.keymaps() end, { desc = "Keymaps" })
      vim.keymap.set('n', "<leader>sl", function() Snacks.picker.loclist() end, { desc = "Location List" })
      vim.keymap.set('n', "<leader>sm", function() Snacks.picker.marks() end, { desc = "Marks" })
      vim.keymap.set('n', "<leader>sM", function() Snacks.picker.man() end, { desc = "Man Pages" })
      vim.keymap.set('n', "<leader>sq", function() Snacks.picker.qflist() end, { desc = "Quickfix List" })
      vim.keymap.set('n', "<leader>sR", function() Snacks.picker.resume() end, { desc = "Resume" })
      vim.keymap.set('n', "<leader>su", function() Snacks.picker.undo() end, { desc = "Undo History" })
    end
  },
}
