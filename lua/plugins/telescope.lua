return {
  {
    "telescope-fzf-native.nvim",
    auto_enable = true,
    dep_of = { "telescope.nvim" },
  },
  {
    "plenary.nvim",
    auto_enable = true,
    dep_of = { "telescope.nvim" },
  },
  {
    "telescope.nvim",
    auto_enable = true,
    cmd = { "Telescope" },
    keys = {
      { "<leader>ff", desc = "Find Files" },
      { "<leader>fg", desc = "Live Grep" },
      { "<leader>fb", desc = "Buffers" },
      { "<leader>fh", desc = "Help Tags" },
      { "<leader>fo", desc = "Old Files" },
      { "<leader>fr", desc = "Resume" },
      { "<leader>fc", desc = "Find in Config" },
    },
    after = function(_)
      local telescope = require('telescope')
      local builtin   = require('telescope.builtin')

      telescope.setup({
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = 'smart_case',
          },
        },
      })
      telescope.load_extension('fzf')

      vim.keymap.set('n', '<leader>ff', builtin.find_files,  { desc = 'Find Files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep,   { desc = 'Live Grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers,     { desc = 'Buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags,   { desc = 'Help Tags' })
      vim.keymap.set('n', '<leader>fo', builtin.oldfiles,    { desc = 'Old Files' })
      vim.keymap.set('n', '<leader>fr', builtin.resume,      { desc = 'Resume' })
      vim.keymap.set('n', '<leader>fc', function()
        builtin.find_files({ cwd = vim.fn.stdpath('config') })
      end, { desc = 'Find in Config' })
    end,
  },
}
