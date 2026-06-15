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
