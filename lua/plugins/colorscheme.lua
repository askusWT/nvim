return {
  {
    -- lazy loaded colorscheme.
    -- This means you will need to add the colorscheme you want to lze sometime before VimEnter is done
    "trigger_colorscheme",
    event = "VimEnter",
    -- lze can load more than just plugins.
    -- The default load field contains vim.cmd.packadd
    -- Here we override it to schedule when our colorscheme is loaded
    load = function(_name)
      -- schedule so it runs after VimEnter
      vim.schedule(function()
        vim.cmd.colorscheme(nixInfo("onedark_dark", "settings", "colorscheme"))
        vim.schedule(function()
          vim.cmd([[hi LineNr guifg=#bb9af7]])
        end)
      end)
    end
  },
  {
    -- NOTE: view these names in the info plugin!
    -- :lua nixInfo.lze.debug.display(nixInfo.plugins)
    -- The display function is from lzextras
    "onedarkpro.nvim",
    auto_enable = true,
    colorscheme = { "onedark", "onedark_dark", "onedark_vivid", "onelight" },
  },
  {
    "vim-moonfly-colors",
    auto_enable = true,
    colorscheme = "moonfly",
  },
  {
    "catppuccin-nvim",
    auto_enable = true,
    colorscheme = { "catppuccin", "catppuccin-latte", "catppuccin-frappe",
                    "catppuccin-macchiato", "catppuccin-mocha" },
    after = function(_)
      require("catppuccin").setup({ flavour = "mocha" })
    end,
  },
}
