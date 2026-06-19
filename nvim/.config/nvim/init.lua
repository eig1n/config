-- ~/.config/nvim/init.lua

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Change this to control the width of the left gutter area.
-- This affects line-number space.
vim.g.left_gutter_width = 1

local opt = vim.opt

-- Core UI
opt.number = true
opt.relativenumber = false
opt.signcolumn = "yes:1"
opt.numberwidth = vim.g.left_gutter_width
opt.foldcolumn = "0"
opt.cursorline = true
opt.termguicolors = true
opt.mouse = "a"
opt.wrap = false

-- Keep the cursor away from the screen edges so the view scrolls earlier.
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Tabs / indentation
-- Your vimrc wanted 4-space indentation; this overrides the earlier 2-space setup.
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true

-- Search / splits
opt.ignorecase = true
opt.smartcase = true
opt.splitright = true
opt.splitbelow = true

-- Search down into subfolders.
-- Makes :find and tab-completion recurse through nested directories.
opt.path:append("**")

-- Display all matching files when you tab-complete commands/paths.
opt.wildmenu = true

-- File state
opt.swapfile = false
opt.undofile = true

-- Use the system clipboard for normal yank/paste.
opt.clipboard = "unnamedplus"

-- Keep the command-line area available.
opt.cmdheight = 1

-- Filetype detection, filetype plugins, indentation rules, and syntax highlighting.
vim.cmd("filetype plugin indent on")
vim.cmd("syntax enable")

-- Make diagnostics easier to see.
vim.diagnostic.config({
  virtual_text = false,--{ spacing = 2, prefix = "●" }, -- set to false if you dislike inline text
  signs = true,
  underline = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
})

vim.keymap.set("n", "<leader>e", function()
  vim.diagnostic.open_float({ scope = "cursor", border = "rounded", source = "if_many" })
end, { desc = "Show diagnostics at cursor" })

vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Send diagnostics to loclist" })


-- Create a recursive ctags file for the current project.
-- Run: :MakeTags
vim.api.nvim_create_user_command("MakeTags", function()
  vim.cmd("silent !ctags -R .")
end, { desc = "Generate ctags for current project" })

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop
if not uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    repo,
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit...", "Normal" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "nvim-lua/plenary.nvim" },

    {
      "nvim-telescope/telescope.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
        require("telescope").setup({
          defaults = {
            sorting_strategy = "ascending",
            layout_config = { prompt_position = "top" },
            file_ignore_patterns = {
              "node_modules",
              "%.git/",
              "dist/",
              "build/",
            },
          },
        })
      end,
    },

    {
      "stevearc/oil.nvim",
      config = function()
        require("oil").setup({
          default_file_explorer = true,
          view_options = { show_hidden = true },
          keymaps = {
            ["<C-h>"] = false,
          },
        })
      end,
    },

    -- Indent guides for code blocks.
    {
      "lukas-reineke/indent-blankline.nvim",
      main = "ibl",
      opts = {
        indent = {
          char = "│",
        },
        scope = {
          enabled = true,
          show_start = false,
          show_end = false,
        },
      },
    },

    -- Blink.cmp: lean completion engine for LSP / path / buffer.
    -- This keeps auto-show off in normal editing mode, but still allows cmdline mode.
    {
      "saghen/blink.cmp",
      version = "*",
      opts = {
        keymap = {
          preset = "default",
        },
        sources = {
          default = { "lsp", "path", "buffer" },
        },
        completion = {
          menu = {
            -- Do not auto-open the completion menu in normal insert mode.
            -- This keeps Blink quieter and avoids fighting with AI suggestions.
            auto_show = function(ctx)
              return ctx.mode ~= "default"
            end,
            border = "rounded",
          },
          documentation = {
            window = {
              border = "rounded",
            },
          },
        },
      },
    },

    -- NeoCodeium: AI autocomplete
    -- Starts disabled so it does not run or send requests until you explicitly enable it.
    -- Toggle with: <leader>ua or :AiToggle
    -- Accept suggestion with: Alt-f in insert mode
   {
      "monkoose/neocodeium",
      event = "VeryLazy",
      dependencies = { "saghen/blink.cmp" },
      config = function()
        local neocodeium = require("neocodeium")
        local blink = require("blink.cmp")
    
        neocodeium.setup({
          enabled = false,
          manual = false,
          show_label = true,
          disable_in_special_buftypes = true,
          log_level = "warn",
          filetypes = {
            help = false,
            gitcommit = false,
            gitrebase = false,
            TelescopePrompt = false,
            ["dap-repl"] = false,
            dotenv = false,
          },
          filter = function(bufnr)
            local name = vim.api.nvim_buf_get_name(bufnr)
            local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
            local basename = vim.fn.fnamemodify(name, ":t")
    
            if ft == "dotenv" then
              return false
            end
            if basename:match("^%.env") then
              return false
            end
            if basename == ".envrc" then
              return false
            end
            if blink.is_visible() then
              return false
            end
    
            return true
          end,
        })
    
        local commands = require("neocodeium.commands")
    
        local function toggle_neocodeium()
          local status = neocodeium.get_status()
          if status == 0 then
            commands.disable(true)
          else
            commands.enable()
          end
        end
    
        vim.api.nvim_create_user_command("AiToggle", toggle_neocodeium, {
          desc = "Toggle NeoCodeium globally",
        })
    
        vim.keymap.set("i", "<A-f>", function()
          neocodeium.accept()
        end, { noremap = true, silent = true, desc = "Accept NeoCodeium suggestion" })

        vim.keymap.set("i", "<A-c>", function()
          neocodeium.cycle(1)
        end, { noremap = true, silent = true, desc = "Cycle NeoCodeium suggestion" })
    
        vim.keymap.set("n", "<leader>ua", toggle_neocodeium, {
          noremap = true,
          silent = true,
          desc = "Toggle NeoCodeium",
        })
      end,
    }, 
    -- LSP + installer stack for Python and C/C++

    {
      "neovim/nvim-lspconfig",
      dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "saghen/blink.cmp",
      },
      config = function()
        require("mason").setup()
    
        require("mason-lspconfig").setup({
          ensure_installed = {
            "basedpyright",
            "ruff",
            "clangd",
          },
        })
    
        local builtin = require("telescope.builtin")
        local capabilities = require("blink.cmp").get_lsp_capabilities()
        local uv = vim.uv or vim.loop
    
        local function find_python_path()
          local candidates = {}
    
          local env = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
          if env then
            candidates[#candidates + 1] = env .. "/bin/python"
            candidates[#candidates + 1] = env .. "/Scripts/python.exe"
          end
    
          local cwd = vim.fn.getcwd()
          candidates[#candidates + 1] = cwd .. "/.venv/bin/python"
          candidates[#candidates + 1] = cwd .. "/.venv/Scripts/python.exe"
          candidates[#candidates + 1] = "python3"
          candidates[#candidates + 1] = "python"
    
          for _, p in ipairs(candidates) do
            if p:find("[/\\]") then
              if uv.fs_stat(p) then
                return p
              end
            elseif vim.fn.executable(p) == 1 then
              return p
            end
          end
        end
    
        local python_path = find_python_path()
    
        vim.lsp.config("basedpyright", {
          capabilities = capabilities,
          settings = {
            python = python_path and {
              pythonPath = python_path,
            } or nil,
            basedpyright = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly",
                useLibraryCodeForTypes = true,
              },
            },
          },
        })
    
        vim.lsp.config("ruff", {
          capabilities = capabilities,
          on_attach = function(client, _)
            client.server_capabilities.hoverProvider = false
          end,
        })
    
        vim.lsp.config("clangd", {
          capabilities = capabilities,
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=never",
          },
        })
    
        -- Toggle LSP from the command line with :lstg
        -- (implemented as a user command plus a command-line abbreviation)
        vim.g.lsp_enabled = true
    
        vim.api.nvim_create_user_command("Lstg", function()
          if vim.g.lsp_enabled then
            vim.cmd("lsp disable")
            vim.g.lsp_enabled = false
            vim.notify("LSP disabled", vim.log.levels.INFO)
          else
            vim.cmd("lsp enable")
            vim.g.lsp_enabled = true
            vim.notify("LSP enabled", vim.log.levels.INFO)
          end
        end, { desc = "Toggle LSP on/off" })
    
        vim.cmd([[cnoreabbrev lstg Lstg]])
    
        -- Enable only if the server binary exists.
        local servers_to_enable = {}
    
        if vim.fn.executable("basedpyright-langserver") == 1 then
          table.insert(servers_to_enable, "basedpyright")
        end
    
        if vim.fn.executable("ruff") == 1 then
          table.insert(servers_to_enable, "ruff")
        end
    
        if vim.fn.executable("clangd") == 1 then
          table.insert(servers_to_enable, "clangd")
        end
    
        for _, server in ipairs(servers_to_enable) do
          vim.lsp.enable(server)
        end
    
        -- Navigation
        vim.keymap.set("n", "gd", builtin.lsp_definitions, { desc = "Go to Definition" })
        vim.keymap.set("n", "gr", builtin.lsp_references, { desc = "Find Usages (Telescope)" })
    
        -- Actions
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Documentation / Hover" })
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename Globally" })
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Auto-fix / Actions" })
    
        -- Meta
        vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "Search Shortcuts" })
    
        -- Auto-format on save.
        vim.api.nvim_create_autocmd("BufWritePre", {
          pattern = { "*.py", "*.c", "*.cpp", "*.h" },
          callback = function()
            vim.lsp.buf.format({ async = false })
          end,
        })
      end,
    },

    {
      "folke/which-key.nvim",
      event = "VeryLazy",
      opts = {},
    },

   -- {
   --   "folke/tokyonight.nvim",
   --   lazy = false,
   --   priority = 1000,
   --   config = function()
   --     -- Automatically applies beautiful colors to Python and C LSP tokens
   --     vim.cmd([[colorscheme tokyonight-moon]]) 
   --   end,
   -- },

  },
  checker = { enabled = true },
})

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Fuzzy finding
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", opts)
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", opts)
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", opts)
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", opts)

-- File browser
map("n", "-", "<cmd>Oil<CR>", opts)

-- Keep deletes off your main clipboard, but still recoverable.
for _, lhs in ipairs({ "d", "D", "c", "C", "x", "X" }) do
  map({ "n", "v" }, lhs, '"1' .. lhs, opts)
end

-- Visual paste without clobbering clipboard.
map("v", "p", '"_dP', opts)
