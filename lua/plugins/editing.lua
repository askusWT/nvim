return {
  {
    "nvim-surround",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function(plugin)
      require('nvim-surround').setup()
    end,
  },
  {
    "mini.nvim",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function()
      require("mini.pairs").setup()
      require("mini.ai").setup()
      require("mini.icons").setup()
      require("mini.icons").mock_nvim_web_devicons() -- satisfy plugins that check for nvim-web-devicons

      -- mini.comment is linewise only: uncommenting prose/block comments strips the
      -- leader and can leave invalid Lua (`--[[ x ]]` -> `[[ x ]]`, `-- [[ header ]]`
      -- -> `[[ header ]]`). Guard: if the buffer parsed before an uncomment and does
      -- not after, restore it. Direction detection stays mini.comment's (standard
      -- toggle: uncomment when every line is already commented, else comment).
      -- CODE VERIFIED (scripts/check.sh; end-to-end on built wrapper)
      local comment_snapshot, comment_cursor
      local function buffer_parses_as_lua(lines)
        return (load(table.concat(lines, '\n'), '=gcc-guard')) ~= nil
      end
      require("mini.comment").setup({
        hooks = {
          pre = function()
            comment_snapshot = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            comment_cursor = vim.api.nvim_win_get_cursor(0)
          end,
          post = function(ev)
            if ev.action ~= 'uncomment' then return end
            local before = comment_snapshot
            comment_snapshot = nil
            if not before then return end
            local after = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            if buffer_parses_as_lua(before) and not buffer_parses_as_lua(after) then
              vim.api.nvim_buf_set_lines(0, 0, -1, false, before)
              if comment_cursor then pcall(vim.api.nvim_win_set_cursor, 0, comment_cursor) end
              vim.notify('gcc: refused - uncommenting would break Lua syntax', vim.log.levels.WARN)
            end
          end,
        },
      })
      require("mini.move").setup()
      require("mini.splitjoin").setup()

      -- THIS CODE IS UNVERIFIED
      require("mini.sessions").setup({
        autoread  = true,  -- restore session for cwd on startup
        autowrite = true,  -- write session on exit
        directory = vim.fn.stdpath('data') .. '/sessions',
      })
      vim.api.nvim_create_user_command('SessionWrite',  function(o) MiniSessions.write(o.args ~= '' and o.args or nil) end,  { nargs = '?', desc = 'Write session' })
      vim.api.nvim_create_user_command('SessionSelect', function()  MiniSessions.select() end,                                { desc = 'Select/load session' })
      vim.api.nvim_create_user_command('SessionDelete', function(o) MiniSessions.delete(o.args ~= '' and o.args or nil) end,  { nargs = '?', desc = 'Delete session' })

      -- THIS CODE IS UNVERIFIED
      require("mini.visits").setup()
      local function visited_files_picker()
        local paths = MiniVisits.list_paths()
        require('telescope.pickers').new({}, {
          prompt_title = 'Visited Files',
          finder   = require('telescope.finders').new_table({ results = paths }),
          sorter   = require('telescope.config').values.generic_sorter({}),
          previewer = require('telescope.config').values.file_previewer({}),
          attach_mappings = function(prompt_bufnr)
            require('telescope.actions').select_default:replace(function()
              local sel = require('telescope.actions.state').get_selected_entry()
              require('telescope.actions').close(prompt_bufnr)
              if sel then vim.cmd.edit(sel[1]) end
            end)
            return true
          end,
        }):find()
      end
      vim.api.nvim_create_user_command('VisitedFiles', visited_files_picker, { desc = 'Visited Files (frecency)' })
      vim.keymap.set('n', '<leader>fv', visited_files_picker, { desc = 'Visited Files (frecency)' })
    end,
  },
  -- THIS CODE IS UNVERIFIED
  {
    "harpoon",
    auto_enable = true,
    keys = {
      { "<leader>a", function() require("harpoon"):list():add() end,
        desc = "Add to harpoon list" },
      { "<C-e>", function()
          require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
        end, desc = "Open harpoon menu" },
    },
    after = function() require("harpoon").setup() end,
  },
  {
    "flash.nvim",
    auto_enable = true,
    keys = {
      { "s", mode = { "n", "x", "o" },
        function() require("flash").jump() end, desc = "Flash jump" },
    },
    after = function() require("flash").setup() end,
  },
}
