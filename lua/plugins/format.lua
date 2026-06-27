return {
  {
    "conform.nvim",
    auto_enable = true,
    cmd = { "ConformInfo" },
    event = { "BufWritePre" },
    keys = {
      { "<leader>cf", desc = "[C]ode [F]ormat", mode = { "n", "v" } },
    },
    after = function(plugin)
      local conform = require("conform")

      conform.setup({
        formatters_by_ft = {
          -- THIS CODE IS UNVERIFIED
          lua        = nixInfo(nil, "settings", "cats", "lua") and { "stylua" } or nil,
          nix        = { "alejandra" },
          sh         = { "shfmt" },
          python     = { "ruff", "isort" },
          go         = { "gofumpt" },
          javascript = { "prettierd" },
          typescript = { "prettierd" },
          yaml       = { "yamlfmt" },
        },
        format_on_save = {
            timeout_ms = 500,
            lsp_format = "fallback"
        },
      })

      vim.keymap.set({ "n", "v" }, "<leader>cf", function()
        conform.format({
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        })
      end, { desc = "[C]ode [F]ormat" })
    end,
  },
  {
    "nvim-lint",
    auto_enable = true,
    event = "FileType",
    after = function(plugin)
      require('lint').linters_by_ft = {
        -- THIS CODE IS UNVERIFIED
        sh         = { 'shellcheck' },
        javascript = { 'eslint' },
        typescript = { 'eslint' },
        python     = { 'ruff' },
        yaml       = { 'yamllint' },
        -- json covered by jsonls LSP
      }

      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },
}
