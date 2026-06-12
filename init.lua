-- NOTE: Welcome to your neovim configuration!
-- The first 100ish lines are setup,
-- the rest is usage of lze and various core plugins!
vim.loader.enable() -- <- bytecode caching
do
  -- Set up a global in a way that also handles non-nix compat
  local ok
  ok, _G.nixInfo = pcall(require, vim.g.nix_info_plugin_name)
  if not ok then
    package.loaded[vim.g.nix_info_plugin_name] = setmetatable({}, {
      __call = function (_, default) return default end
    })
    _G.nixInfo = require(vim.g.nix_info_plugin_name)
    -- If you always use the fetcher function to fetch nix values,
    -- rather than indexing into the tables directly,
    -- it will use the value you specified as the default
    -- TODO: for non-nix compat, vim.pack.add in another file and require here.
  end
  nixInfo.isNix = vim.g.nix_info_plugin_name ~= nil
  ---@module 'lzextras'
  ---@type lzextras | lze
  nixInfo.lze = setmetatable(require('lze'), getmetatable(require('lzextras')))
  function nixInfo.get_nix_plugin_path(name)
    return nixInfo(nil, "plugins", "lazy", name) or nixInfo(nil, "plugins", "start", name)
  end
end
nixInfo.lze.register_handlers {
  {
    -- adds an `auto_enable` field to lze specs
    -- if true, will disable it if not installed by nix.
    -- if string, will disable if that name was not installed by nix.
    -- if a table of strings, it will disable if any were not.
    spec_field = "auto_enable",
    set_lazy = false,
    modify = function(plugin)
      if vim.g.nix_info_plugin_name then
        if type(plugin.auto_enable) == "table" then
          for _, name in pairs(plugin.auto_enable) do
            if not nixInfo.get_nix_plugin_path(name) then
              plugin.enabled = false
              break
            end
          end
        elseif type(plugin.auto_enable) == "string" then
          if not nixInfo.get_nix_plugin_path(plugin.auto_enable) then
            plugin.enabled = false
          end
        elseif type(plugin.auto_enable) == "boolean" and plugin.auto_enable then
          if not nixInfo.get_nix_plugin_path(plugin.name) then
            plugin.enabled = false
          end
        end
      end
      return plugin
    end,
  },
  {
    -- we made an options.settings.cats with the value of enable for our top level specs
    -- give for_cat = "name" to disable if that one is not enabled
    spec_field = "for_cat",
    set_lazy = false,
    modify = function(plugin)
      if vim.g.nix_info_plugin_name then
        if type(plugin.for_cat) == "string" then
          plugin.enabled = nixInfo(false, "settings", "cats", plugin.for_cat)
        end
      end
      return plugin
    end,
  },
  -- From lzextras. This one makes it so that
  -- you can set up lsps within lze specs,
  -- and trigger lspconfig setup hooks only on the correct filetypes
  -- It is (unfortunately) important that it be registered after the above 2,
  -- as it also relies on the modify hook, and the value of enabled at that point
  nixInfo.lze.lsp,
}

-- NOTE: This config uses lzextras.lsp handler https://github.com/BirdeeHub/lzextras?tab=readme-ov-file#lsp-handler
-- Because we have the paths, we can set a more performant fallback function
-- for when you don't provide a filetype to trigger on yourself.
-- If you do provide a filetype, this will never be called.
nixInfo.lze.h.lsp.set_ft_fallback(function(name)
  local lspcfg = nixInfo.get_nix_plugin_path "nvim-lspconfig"
  if lspcfg then
    local ok, cfg = pcall(dofile, lspcfg .. "/lsp/" .. name .. ".lua")
    return (ok and cfg or {}).filetypes or {}
  else
    -- the less performant thing we are trying to avoid at startup
    return (vim.lsp.config[name] or {}).filetypes or {}
  end
end)

-- Crostini clipboard: OSC 52 write works via Zellij; read does not (Zellij unimplemented).
-- xclip does NOT reach ChromeOS clipboard (sommelier doesn't bridge it).
-- To paste FROM ChromeOS into nvim: use Ctrl+Shift+V in insert mode (terminal paste).
vim.g.clipboard = {
  name = 'OSC52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = function() return {} end,
    ['*'] = function() return {} end,
  },
}

-- NOTE: These 2 should be set up before any plugins with keybinds are loaded.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- allow .nvim.lua in current dir and parents (project config)
vim.o.exrc = false -- can be toggled off in that file to stop it from searching further

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Set highlight on search
vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Indent
-- vim.o.smarttab = true
vim.opt.cpoptions:append('I')
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.autoindent = true
vim.o.tabstop = 2
-- vim.o.softtabstop = 4
-- vim.o.shiftwidth = 4

-- stops line wrapping from being confusing
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'
vim.wo.relativenumber = true

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 500

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menu,preview,noselect'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

vim.o.splitright = true
vim.o.splitbelow = true
vim.o.cursorline = true
vim.o.shiftwidth = 2
vim.o.wrap = false

-- [[ Disable auto comment on enter ]]
-- See :help formatoptions
vim.api.nvim_create_autocmd("FileType", {
  desc = "remove formatoptions",
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

vim.g.netrw_liststyle=0
vim.g.netrw_banner=0

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = 'Moves Line Down' })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = 'Moves Line Up' })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = 'Scroll Down' })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = 'Scroll Up' })
vim.keymap.set("n", "n", "nzzzv", { desc = 'Next Search Result' })
vim.keymap.set("n", "N", "Nzzzv", { desc = 'Previous Search Result' })

vim.keymap.set("n", "<leader><leader>[", "<cmd>bprev<CR>", { desc = 'Previous buffer' })
vim.keymap.set("n", "<leader><leader>]", "<cmd>bnext<CR>", { desc = 'Next buffer' })
vim.keymap.set("n", "<leader><leader>l", "<cmd>b#<CR>", { desc = 'Last buffer' })
vim.keymap.set("n", "<leader><leader>d", "<cmd>bdelete<CR>", { desc = 'delete buffer' })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Window navigation
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus left' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus down' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus up' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus right' })

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Prev diagnostic' })

-- unnamedplus so yank triggers the OSC52 copy provider above.
-- Paste from ChromeOS into nvim: Ctrl+Shift+V in insert mode (not `p`).
vim.o.clipboard = 'unnamedplus'

-- Explicit clipboard keybindings (still useful for visual mode etc.)
vim.keymap.set({"v", "x", "n"}, '<leader>y', '"+y', { noremap = true, silent = true, desc = 'Yank to clipboard' })
vim.keymap.set({"n", "v", "x"}, '<leader>Y', '"+yy', { noremap = true, silent = true, desc = 'Yank line to clipboard' })
vim.keymap.set({'n', 'v', 'x'}, '<leader>p', '"+p', { noremap = true, silent = true, desc = 'Paste from clipboard' })
vim.keymap.set('i', '<C-p>', '<C-r><C-p>+', { noremap = true, silent = true, desc = 'Paste from clipboard from within insert mode' })
vim.keymap.set("x", "<leader>P", '"_dP', { noremap = true, silent = true, desc = 'Paste over selection without erasing unnamed register' })

-- NOTE: You will likely want to break this up into more files.
-- You can call this more than once.
-- You can also include other files from within the specs via an `import` spec.
-- see https://github.com/BirdeeHub/lze?tab=readme-ov-file#structuring-your-plugins
nixInfo.lze.load {
  {
    -- lze specs need a name
    "trigger_colorscheme",
    -- lazy loaded colorscheme.
    -- This means you will need to add the colorscheme you want to lze sometime before VimEnter is done
    event = "VimEnter",
    -- Also, lze can load more than just plugins.
    -- The default load field contains vim.cmd.packadd
    -- Here we override it to schedule when our colorscheme is loaded
    load = function(_name)
      -- schedule so it runs after VimEnter
      vim.schedule(function()
        vim.cmd.colorscheme(nixInfo("onedark_dark", "settings", "colorscheme"))
        vim.schedule(function()
          -- I like this color. Use vim.schedule again to set it after the colorscheme is finished
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
    auto_enable = true, -- <- auto enable is useful here
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
  {
    "snacks.nvim",
    auto_enable = true,
    -- snacks makes a global, and then lazily loads itself
    lazy = false,
    -- priority only affects startup plugins
    -- unless otherwise specified by a particular handler
    priority = 1000,
    after = function(plugin)
      -- I also like this color
      vim.api.nvim_set_hl(0, "MySnacksIndent", { fg = "#32a88f" })
      require('snacks').setup({
        explorer = { replace_netrw = true, },
        input = {},
        notifier = {},
        quickfile = {},
        scroll = {},
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
        scope = {},
        indent = {
          scope = {
            hl = 'MySnacksIndent',
          },
          chunk = {
            -- enabled = true,
            hl = 'MySnacksIndent',
          }
        },
        statuscolumn = {
          left = { "mark", "git" }, -- priority of signs on the left (high to low)
          right = { "sign", "fold" }, -- priority of signs on the right (high to low)
          folds = {
            open = false, -- show open fold icons
            git_hl = false, -- use Git Signs hl for fold icons
          },
          git = {
            -- patterns to match Git signs
            patterns = { "GitSign", "MiniDiffSign" },
          },
          refresh = 50, -- refresh at most every 50ms
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
      vim.api.nvim_create_user_command('LazyGit',  function() Snacks.lazygit.open() end, { desc = 'Open LazyGit' })
      vim.api.nvim_create_user_command('Explorer', function() Snacks.explorer.open() end, { desc = 'Open file explorer' })
      vim.api.nvim_create_user_command('Grep',     function() Snacks.picker.grep() end, { desc = 'Grep files' })
      -- NOTE: we aren't loading this lazily, and the keybinds already are so it is fine to just set these here
      vim.keymap.set("n", "-", function() Snacks.explorer.open() end, { desc = 'Snacks file explorer' })
      vim.keymap.set("n", "<c-\\>", function() Snacks.terminal.open() end, { desc = 'Snacks Terminal' })
      vim.keymap.set("n", "<leader>gg", function() Snacks.lazygit.open() end, { desc = 'LazyGit' })
      vim.keymap.set('n', "<leader>sf", function() Snacks.picker.smart() end, { desc = "Smart Find Files" })
      vim.keymap.set('n', "<leader><leader>s", function() Snacks.picker.buffers() end, { desc = "Search Buffers" })
      -- find
      vim.keymap.set('n', "<leader>ff", function() Snacks.picker.files() end, { desc = "Find Files" })
      vim.keymap.set('n', "<leader>fg", function() Snacks.picker.git_files() end, { desc = "Find Git Files" })
      -- Grep
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

          -- we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
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
    priority = 100, -- <- run lsp hook before lspconfig's hook
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
    -- name of the lsp
    "lua_ls",
    for_cat = "lua",
    -- provide a table containing filetypes,
    -- and then whatever your functions defined in the function type specs expect.
    -- in our case, it just expects the normal lspconfig setup options,
    -- but with a default on_attach and capabilities
    lsp = {
      -- if you provide the filetypes it doesn't ask lspconfig for the filetypes
      -- (meaning it doesn't call the callback function we defined in the main init.lua)
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
    -- also these are regular specs and you can use before and after and all the other normal fields
  },
  {
    "nixd",
    enabled = nixInfo.isNix, -- mason doesn't have nixd
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
  { "nvim-treesitter",
    lazy = false,
    auto_enable = true,
    after = function(plugin)
      ---@param buf integer
      ---@param language string
      local function treesitter_try_attach(buf, language)
        -- check if parser exists and load it
        if not vim.treesitter.language.add(language) then
          return false
        end
        -- enables syntax highlighting and other treesitter features
        vim.treesitter.start(buf, language)

        -- enables treesitter based folds
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo.foldmethod = "expr"
        -- ensure folds are open to begin with
        vim.o.foldlevel = 99

        -- enables treesitter based indentation
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

        return true
      end

      -- withAllGrammars pre-builds everything; no runtime install needed
      -- checkhealth skipped: large buffer causes 7-10s C-level treesitter parse delay
      local ts_skip = { checkhealth = true }
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local buf, filetype = args.buf, args.match
          if ts_skip[filetype] then return end
          local language = vim.treesitter.language.get_lang(filetype)
          if not language then return end
          vim.schedule(function()
            treesitter_try_attach(buf, language)
          end)
        end,
      })
    end,
  },
  {
    "nvim-treesitter-textobjects",
    auto_enable = true,
    lazy = false,
    before = function(plugin)
      -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/tree/main?tab=readme-ov-file#using-a-package-manager
      -- Disable entire built-in ftplugin mappings to avoid conflicts.
      -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
      vim.g.no_plugin_maps = true

      -- Or, disable per filetype (add as you like)
      -- vim.g.no_python_maps = true
      -- vim.g.no_ruby_maps = true
      -- vim.g.no_rust_maps = true
      -- vim.g.no_go_maps = true
    end,
    after = function(plugin)
      require("nvim-treesitter-textobjects").setup {
        select = {
          -- Automatically jump forward to textobj, similar to targets.vim
          lookahead = true,
          -- You can choose the select mode (default is charwise 'v')
          --
          -- Can also be a function which gets passed a table with the keys
          -- * query_string: eg '@function.inner'
          -- * method: eg 'v' or 'o'
          -- and should return the mode ('v', 'V', or '<c-v>') or a table
          -- mapping query_strings to modes.
          selection_modes = {
            ['@parameter.outer'] = 'v', -- charwise
            ['@function.outer'] = 'V', -- linewise
            -- ['@class.outer'] = '<c-v>', -- blockwise
          },
          -- If you set this to `true` (default is `false`) then any textobject is
          -- extended to include preceding or succeeding whitespace. Succeeding
          -- whitespace has priority in order to act similarly to eg the built-in
          -- `ap`.
          --
          -- Can also be a function which gets passed a table with the keys
          -- * query_string: eg '@function.inner'
          -- * selection_mode: eg 'v'
          -- and should return true of false
          include_surrounding_whitespace = false,
        },
      }

      -- keymaps
      -- You can use the capture groups defined in `textobjects.scm`
      vim.keymap.set({ "x", "o" }, "am", function()
        require "nvim-treesitter-textobjects.select".select_textobject("@function.outer", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "im", function()
        require "nvim-treesitter-textobjects.select".select_textobject("@function.inner", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "ac", function()
        require "nvim-treesitter-textobjects.select".select_textobject("@class.outer", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "ic", function()
        require "nvim-treesitter-textobjects.select".select_textobject("@class.inner", "textobjects")
      end)
      -- You can also use captures from other query groups like `locals.scm`
      vim.keymap.set({ "x", "o" }, "as", function()
        require "nvim-treesitter-textobjects.select".select_textobject("@local.scope", "locals")
      end)

      -- NOTE: for more textobjects options, see the following link.
      -- This template is using the new `main` branch of the repo.
      -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/tree/main
    end,
  },
  {
    "conform.nvim",
    auto_enable = true,
    -- cmd = { "" },
    -- event = "",
    -- ft = "",
    keys = {
      { "<leader>FF", desc = "[F]ormat [F]ile" },
    },
    -- colorscheme = "",
    after = function (plugin)
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

      vim.keymap.set({ "n", "v" }, "<leader>FF", function()
        conform.format({
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        })
      end, { desc = "[F]ormat [F]ile" })
    end,
  },
  {
    "nvim-lint",
    auto_enable = true,
    -- cmd = { "" },
    event = "FileType",
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function (plugin)
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
  {
    "cmp-cmdline",
    auto_enable = true,
    on_plugin = { "blink.cmp" },
    load = nixInfo.lze.loaders.with_after,
  },
  {
    "blink.compat",
    auto_enable = true,
    dep_of = { "cmp-cmdline" },
  },
  {
    "colorful-menu.nvim",
    auto_enable = true,
    on_plugin = { "blink.cmp" },
  },
  {
    "blink.cmp",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function (_)
      require("blink.cmp").setup({
        -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
        -- See :h blink-cmp-config-keymap for configuring keymaps
        keymap =  {
          preset = 'default',
          ['<Up>'] = { 'select_prev', 'fallback' },
          ['<Down>'] = { 'select_next', 'fallback' },
          ['<CR>'] = { 'accept', 'fallback' },
        },
        cmdline = {
          enabled = true,
          completion = {
            menu = {
              auto_show = true,
            },
          },
          sources = function()
            local type = vim.fn.getcmdtype()
            -- Search forward and backward
            if type == '/' or type == '?' then return { 'buffer' } end
            -- Commands
            if type == ':' or type == '@' then return { 'cmdline', 'cmp_cmdline' } end
            return {}
          end,
        },
        fuzzy = {
          sorts = {
            'exact',
            -- defaults
            'score',
            'sort_text',
          },
        },
        signature = {
          enabled = true,
          window = {
            show_documentation = true,
          },
        },
        completion = {
          menu = {
            draw = {
              treesitter = { 'lsp' },
              components = {
                label = {
                  text = function(ctx)
                    return require("colorful-menu").blink_components_text(ctx)
                  end,
                  highlight = function(ctx)
                    return require("colorful-menu").blink_components_highlight(ctx)
                  end,
                },
              },
            },
          },
          documentation = {
            auto_show = true,
          },
        },
        sources = {
          default = { 'lsp', 'path', 'buffer', 'omni' },
          providers = {
            path = {
              score_offset = 50,
            },
            lsp = {
              score_offset = 40,
            },
            cmp_cmdline = {
              name = 'cmp_cmdline',
              module = 'blink.compat.source',
              score_offset = -100,
              opts = {
                cmp_name = 'cmdline',
              },
            },
          },
        },
      })
    end,
  },
  {
    "nvim-surround",
    auto_enable = true,
    event = "DeferredUIEnter",
    -- keys = "",
    after = function(plugin)
      require('nvim-surround').setup()
    end,
  },
  {
    "vim-startuptime",
    auto_enable = true,
    cmd = { "StartupTime" },
    before = function(_)
      vim.g.startuptime_event_width = 0
      vim.g.startuptime_tries = 10
      vim.g.startuptime_exe_path = nixInfo(vim.v.progpath, "progpath")
    end,
  },
  {
    "fidget.nvim",
    auto_enable = true,
    event = "DeferredUIEnter",
    -- keys = "",
    after = function(plugin)
      require('fidget').setup({})
    end,
  },
  {
    "lualine.nvim",
    auto_enable = true,
    -- cmd = { "" },
    event = "DeferredUIEnter",
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function (plugin)
      require('lualine').setup({
        options = {
          icons_enabled = true,
          theme = 'auto',
          component_separators = '|',
          section_separators = '',
        },
        sections = {
          lualine_c = {
            { 'filename', path = 1, status = true, },
          },
        },
        inactive_sections = {
          lualine_b = {
            { 'filename', path = 3, status = true, },
          },
          lualine_x = {'filetype'},
        },
        tabline = {
          lualine_a = { 'buffers' },
          -- if you use lualine-lsp-progress, I have mine here instead of fidget
          -- lualine_b = { 'lsp_progress', },
          lualine_z = { 'tabs' }
        },
      })
    end,
  },
  {
    "gitsigns.nvim",
    auto_enable = true,
    event = "DeferredUIEnter",
    -- cmd = { "" },
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function (plugin)
      require('gitsigns').setup({
        -- See `:help gitsigns.txt`
        signs = {
          add = { text = '+' },
          change = { text = '~' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map({ 'n', 'v' }, ']c', function()
            if vim.wo.diff then
              return ']c'
            end
            vim.schedule(function()
              gs.next_hunk()
            end)
            return '<Ignore>'
          end, { expr = true, desc = 'Jump to next hunk' })

          map({ 'n', 'v' }, '[c', function()
            if vim.wo.diff then
              return '[c'
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return '<Ignore>'
          end, { expr = true, desc = 'Jump to previous hunk' })

          -- Actions
          -- visual mode
          map('v', '<leader>hs', function()
            gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
          end, { desc = 'stage git hunk' })
          map('v', '<leader>hr', function()
            gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
          end, { desc = 'reset git hunk' })
          -- normal mode
          map('n', '<leader>gs', gs.stage_hunk, { desc = 'git stage hunk' })
          map('n', '<leader>gr', gs.reset_hunk, { desc = 'git reset hunk' })
          map('n', '<leader>gS', gs.stage_buffer, { desc = 'git Stage buffer' })
          map('n', '<leader>gu', gs.undo_stage_hunk, { desc = 'undo stage hunk' })
          map('n', '<leader>gR', gs.reset_buffer, { desc = 'git Reset buffer' })
          map('n', '<leader>gp', gs.preview_hunk, { desc = 'preview git hunk' })
          map('n', '<leader>gb', function()
            gs.blame_line { full = false }
          end, { desc = 'git blame line' })
          map('n', '<leader>gd', gs.diffthis, { desc = 'git diff against index' })
          map('n', '<leader>gD', function()
            gs.diffthis '~'
          end, { desc = 'git diff against last commit' })

          -- Toggles
          map('n', '<leader>gtb', gs.toggle_current_line_blame, { desc = 'toggle git blame line' })
          map('n', '<leader>gtd', gs.toggle_deleted, { desc = 'toggle git show deleted' })

          -- Text object
          map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'select git hunk' })
        end,
      })
      vim.cmd([[hi GitSignsAdd guifg=#04de21]])
      vim.cmd([[hi GitSignsChange guifg=#83fce6]])
      vim.cmd([[hi GitSignsDelete guifg=#fa2525]])
    end,
  },
  -- THIS CODE IS UNVERIFIED
  {
    "nui.nvim",
    auto_enable = true,
    dep_of = { "fine-cmdline.nvim" },
  },
  {
    "fine-cmdline.nvim",
    auto_enable = true,
    event = "VimEnter",
    after = function(_)
      local fine = require('fine-cmdline')
      fine.setup({
        cmdline = { enable_keymaps = true, smart_history = true },
        popup   = { position = { row = '30%', col = '50%' }, size = { width = '60%' } },
      })
      vim.api.nvim_set_keymap('n', ':', '<cmd>FineCmdline<CR>', { noremap = true })
    end,
  },
  {
    "dressing.nvim",
    auto_enable = true,
    event = "VimEnter",
    after = function(_)
      require('dressing').setup({
        input  = { enabled = false }, -- snacks.input handles vim.ui.input
        select = { enabled = true },
      })
    end,
  },
  {
    "which-key.nvim",
    auto_enable = true,
    -- cmd = { "" },
    event = "DeferredUIEnter",
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function (plugin)
      require('which-key').setup({
      })
      require('which-key').add {
        { "<leader><leader>",  group = "Buffers" },
        { "<leader><leader>_", hidden = true },
        { "<leader>c",         group = "Code" },
        { "<leader>c_",        hidden = true },
        { "<leader>d",         group = "Document" },
        { "<leader>d_",        hidden = true },
        { "<leader>f",         group = "Find Files" },
        { "<leader>f_",        hidden = true },
        { "<leader>g",         group = "Git" },
        { "<leader>gg",        desc = "LazyGit" },
        { "<leader>g_",        hidden = true },
        { "<leader>m",         group = "Markdown" },
        { "<leader>o",         group = "Opencode" },
        { "<leader>o_",        hidden = true },
        { "<leader>m_",        hidden = true },
        { "<leader>r",         group = "Rename" },
        { "<leader>r_",        hidden = true },
        { "<leader>s",         group = "Search" },
        { "<leader>s_",        hidden = true },
        { "<leader>t",         group = "Toggles" },
        { "<leader>tb",        desc = "Toggle git blame" },
        { "<leader>td",        desc = "Toggle diagnostics" },
        { "<leader>tw",        desc = "Toggle word wrap" },
        { "<leader>t_",        hidden = true },
        { "<leader>w",         group = "Workspace" },
        { "<leader>w_",        hidden = true },
      }

      -- Toggles
      vim.keymap.set('n', '<leader>tb', function() require('gitsigns').toggle_current_line_blame() end, { desc = 'Toggle git blame' })
      vim.keymap.set('n', '<leader>td', function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end, { desc = 'Toggle diagnostics' })
      vim.keymap.set('n', '<leader>tw', function() vim.o.wrap = not vim.o.wrap end, { desc = 'Toggle word wrap' })
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
      pcall(require, "opencode")
      local oc = require("opencode")
      vim.keymap.set('n', '<leader>ot', oc.toggle,                                             { desc = 'Toggle panel' })
      vim.keymap.set('n', '<leader>oa', oc.ask,                                              { desc = 'Ask' })
      vim.keymap.set('n', '<leader>ob', function() oc.prompt('@buffers') end,                { desc = 'Share all buffers' })
      vim.keymap.set('n', '<leader>os', oc.select,                                           { desc = 'Select prompt' })
      vim.keymap.set('n', '<leader>oS', oc.select_session,                                   { desc = 'Select session' })
      vim.keymap.set('n', '<leader>or', oc.select_server,                                    { desc = 'Select server' })
      vim.keymap.set('n', '<leader>od', function() oc.prompt('@nvim diagnostics') end,       { desc = 'Explain diagnostics' })
      -- operator maps: work with motions (e.g. <leader>oeip) AND visual selection
      vim.keymap.set('n', '<leader>oe', function() return oc.operator('@nvim explain') end,  { expr = true, desc = 'Explain (operator)' })
      vim.keymap.set('x', '<leader>oe', function() oc.prompt('@nvim explain') end,           { desc = 'Explain selection' })
      vim.keymap.set('n', '<leader>of', function() return oc.operator('@nvim fix') end,      { expr = true, desc = 'Fix (operator)' })
      vim.keymap.set('x', '<leader>of', function() oc.prompt('@nvim fix') end,               { desc = 'Fix selection' })
      vim.keymap.set('n', '<leader>oR', function() return oc.operator('@nvim review') end,   { expr = true, desc = 'Review (operator)' })
      vim.keymap.set('x', '<leader>oR', function() oc.prompt('@nvim review') end,            { desc = 'Review selection' })
      local subcmds = { 'toggle', 'ask', 'prompt', 'select', 'select_session', 'select_server', 'start', 'stop' }
      vim.api.nvim_create_user_command('Opencode', function(opts)
        local arg = opts.args
        if arg == '' or arg == 'toggle' then
          oc.toggle()
        elseif arg == 'ask' then
          oc.ask()
        elseif arg == 'select' then
          oc.select()
        elseif arg == 'select_session' then
          oc.select_session()
        elseif arg == 'select_server' then
          oc.select_server()
        elseif arg == 'start' then
          oc.start()
        elseif arg == 'stop' then
          oc.stop()
        else
          -- treat as a prompt string; inject @nvim context automatically
          oc.prompt('@nvim ' .. arg)
        end
      end, { nargs = '?', complete = function() return subcmds end, desc = 'Opencode commands' })
    end,
  },
}

