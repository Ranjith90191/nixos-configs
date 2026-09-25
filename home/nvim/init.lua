-- 1. Set your "Leader" key to the Spacebar (Kept for other plugins, but unused below)
vim.g.mapleader = " "

-- 2. Auto-install Lazy.nvim (Updated for Neovim 0.12+ using vim.uv)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 3. Install and configure Nvim-Tree (Updated with custom shortcut)
require("lazy").setup({
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      -- Define custom keyboard shortcuts for Nvim-Tree
      local function my_on_attach(bufnr)
        local api = require("nvim-tree.api")

        -- Load default mappings first
        api.config.mappings.default_on_attach(bufnr)

        -- Add custom mapping: Press 't' to open in a new tab
        vim.keymap.set('n', 't', api.node.open.tab, { buffer = bufnr, noremap = true, silent = true, nowait = true })
      end

      require("nvim-tree").setup({
        on_attach = my_on_attach, -- Applies your custom shortcut
        view = {
          width = 30,
          side = "left",
        },
      })
    end,
  },
{
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- Required specifically for Neovim 0.12+
    config = function()
      -- 1. Enable treesitter syntax highlighting for every file you open
      vim.api.nvim_create_autocmd('FileType', {
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
      
      -- 2. Define the languages you want to install parsers for
      local parsers = { "c", "lua", "vim", "vimdoc", "query", "javascript", "python", "html", "css" }
      
      -- 3. Install them automatically if they are missing
      local already_installed = require('nvim-treesitter.config').get_installed()
      local to_install = vim.iter(parsers)
        :filter(function(parser)
          return not vim.tbl_contains(already_installed, parser)
        end)
        :totable()
        
      if #to_install > 0 then
        require('nvim-treesitter').install(to_install)
      end
    end,
  },
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("cyberdream").setup({
        transparent = true, -- Perfectly inherits your Ghostty background
        italic_comments = true,
        hide_fillchars = true,
        borderless_telescope = true,
      })
      vim.cmd([[colorscheme cyberdream]])
    end,
  },
})

-- 4. Global Alt Key Mappings

-- Pressing Alt + e will open/close the explorer
vim.keymap.set('n', '<A-e>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })

-- Press Alt + f to focus the explorer without toggling it closed
vim.keymap.set('n', '<A-f>', ':NvimTreeFocus<CR>', { noremap = true, silent = true })

-- Press Alt + t to go to the next tab
vim.keymap.set('n', '<A-t>', 'gt', { noremap = true, silent = true })

-- Press Alt + Shift + t (Alt + T) to go to the previous tab
vim.keymap.set('n', '<A-T>', 'gT', { noremap = true, silent = true })

-- Enable standard line numbers (shows absolute number on current line)
vim.opt.number = true

-- Enable relative line numbers (shows distances on all other lines)
vim.opt.relativenumber = true

-- 1. Enable cursorline so Neovim knows to use CursorLineNr
vim.opt.cursorline = true

-- 2. Hook into ColorScheme so your theme doesn't overwrite your colors
local function set_line_colors()
  vim.api.nvim_set_hl(0, "LineNr", { fg = "#22d3ee", bold = true })       -- Cyan
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ff0055", bold = true }) -- Vibrant Red
end

set_line_colors()

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = set_line_colors,
})
