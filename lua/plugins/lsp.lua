return {
  {
    "nvim-lspconfig",
    auto_enable = true,
    -- NOTE: define a function for lsp,
    -- and it will run for all specs with type(plugin.lsp) == table
    -- when their filetype trigger loads them
    lsp = function(plugin)
      vim.lsp.config(plugin.name, plugin.lsp or {})
      vim.lsp.enable(plugin.name)
    end,
    -- set up our on_attach function once before the spec loads
    before = function(_)
      vim.lsp.config('*', {
        on_attach = function(_, bufnr)

          local nmap = function(keys, func, desc)
            if desc then
              desc = 'LSP: ' .. desc
            end
            vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
          end

          nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
          nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
          nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
          nmap('gr', function() Snacks.picker.lsp_references() end, '[G]oto [R]eferences')
          nmap('gI', function() Snacks.picker.lsp_implementations() end, '[G]oto [I]mplementation')
          nmap('<leader>ds', function() Snacks.picker.lsp_symbols() end, '[D]ocument [S]ymbols')
          nmap('<leader>ws', function() Snacks.picker.lsp_workspace_symbols() end, '[W]orkspace [S]ymbols')

          -- See `:help K` for why this keymap
          nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
          nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

          -- Lesser used LSP functionality
          nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
          nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
          nmap('<leader>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, '[W]orkspace [L]ist Folders')

          -- Create a command `:Format` local to the LSP buffer
          vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
            vim.lsp.buf.format()
          end, { desc = 'Format current buffer with LSP' })
        end
      })
    end,
  },
  {
    "mason.nvim",
    enabled = not nixInfo.isNix,
    priority = 100, -- run lsp hook before lspconfig's hook
    on_plugin = { "nvim-lspconfig" },
    lsp = function(plugin)
      vim.cmd.MasonInstall(plugin.name)
    end,
  },
  {
    -- lazydev makes your lua lsp load only the relevant definitions for a file.
    -- It also gives us a nice way to correlate globals we create with files.
    "lazydev.nvim",
    auto_enable = true,
    cmd = { "LazyDev" },
    ft = "lua",
    after = function(_)
      require('lazydev').setup({
        library = {
          { words = { "nixInfo%.lze" }, path = nixInfo("lze", "plugins", "start", "lze") .. '/lua', },
          { words = { "nixInfo%.lze" }, path = nixInfo("lzextras", "plugins", "start", "lzextras") .. '/lua' },
        },
      })
    end,
  },
  {
    "lua_ls",
    for_cat = "lua",
    lsp = {
      filetypes = { 'lua' },
      settings = {
        Lua = {
          signatureHelp = { enabled = true },
          diagnostics = {
            globals = { "nixInfo", "vim", },
            disable = { 'missing-fields' },
          },
        },
      },
    },
  },
  {
    "nixd",
    enabled = nixInfo.isNix,
    for_cat = "nix",
    lsp = {
      filetypes = { "nix" },
      settings = {
        nixd = {
          nixpkgs = {
            expr = [[import <nixpkgs> {}]],
          },
          options = {
          },
          formatting = {
            command = { "nixfmt" }
          },
          diagnostic = {
            suppress = {
              "sema-escaping-with"
            }
          }
        }
      },
    },
  },
  -- THIS CODE IS UNVERIFIED
  -- LSPs provided via penguin packages / system PATH (not pinned in wrapper)
  {
    "rust_analyzer",
    enabled = nixInfo.isNix,
    lsp = {
      filetypes = { "rust" },
      settings = {
        ["rust-analyzer"] = {
          cargo = { allFeatures = true },
          checkOnSave = { command = "clippy" },
        },
      },
    },
  },
  { "ts_ls",       enabled = nixInfo.isNix, lsp = { filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" } } },
  { "bashls",      enabled = nixInfo.isNix, lsp = { filetypes = { "sh", "bash" } } },
  { "yamlls",      enabled = nixInfo.isNix, lsp = { filetypes = { "yaml" } } },
  { "nil_ls",      enabled = nixInfo.isNix, lsp = { filetypes = { "nix" } } },
  { "pyright",     enabled = nixInfo.isNix, lsp = { filetypes = { "python" } } },
  { "marksman",    enabled = nixInfo.isNix, lsp = { filetypes = { "markdown" } } },
  { "gopls",       enabled = nixInfo.isNix, lsp = { filetypes = { "go" } } },
  { "clangd",      enabled = nixInfo.isNix, lsp = { filetypes = { "c", "cpp" } } },
  { "jsonls",      enabled = nixInfo.isNix, lsp = { filetypes = { "json" } } },
  { "dockerls",    enabled = nixInfo.isNix, lsp = { filetypes = { "dockerfile" } } },
  { "lemminx",     enabled = nixInfo.isNix, lsp = { filetypes = { "xml" } } },
  { "systemd_ls",  enabled = nixInfo.isNix, lsp = { filetypes = { "systemd" } } },
  { "nginx_language_server", enabled = nixInfo.isNix, lsp = { filetypes = { "nginx" } } },
}
