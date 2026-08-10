-- Neovim config — Fleet optimized minimal setup
-- 2026-06-09

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 50
vim.opt.clipboard = 'unnamedplus'
vim.opt.mouse = 'a'
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ 'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- Theme
  { 'catppuccin/nvim', name = 'catppuccin', priority = 1000,
    config = function()
      require('catppuccin').setup({ flavour = 'mocha' })
      vim.cmd.colorscheme 'catppuccin'
    end },

  -- Status line
  { 'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({ options = { theme = 'catppuccin' } })
    end },

  -- Fuzzy finder
  { 'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local t = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', t.find_files, { desc = 'Find files' })
      vim.keymap.set('n', '<leader>fg', t.live_grep, { desc = 'Live grep' })
      vim.keymap.set('n', '<leader>fb', t.buffers, { desc = 'Buffers' })
      vim.keymap.set('n', '<leader>fr', t.oldfiles, { desc = 'Recent files' })
    end },

  -- Syntax highlighting
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = { 'lua', 'python', 'javascript', 'typescript',
          'go', 'rust', 'json', 'yaml', 'toml', 'bash', 'markdown' },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end },

  -- Git integration
  { 'lewis6991/gitsigns.nvim', config = true },

  -- Comments
  { 'numToStr/Comment.nvim', config = true },

  -- Auto pairs
  { 'windwp/nvim-autopairs', event = 'InsertEnter', config = true },

  -- Which-key (keybinding hints)
  { 'folke/which-key.nvim', config = true },

  -- File explorer
  { 'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('nvim-tree').setup()
      vim.keymap.set('n', '<leader>e', '<cmd>NvimTreeToggle<cr>', { desc = 'Toggle file tree' })
    end },
}, {
  checker = { enabled = true, notify = false },
})

-- Keymaps
vim.keymap.set('n', '<leader>w', '<cmd>write<cr>', { desc = 'Save' })
vim.keymap.set('n', '<leader>q', '<cmd>quit<cr>', { desc = 'Quit' })
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<cr>')
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move left' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move down' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move up' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move right' })
vim.keymap.set('n', '<leader>/', '<cmd>nohlsearch<cr>', { desc = 'Clear search' })
vim.keymap.set('n', '<leader>bn', '<cmd>bnext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bp', '<cmd>bprev<cr>', { desc = 'Prev buffer' })
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<cr>', { desc = 'Delete buffer' })
-- Move lines
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")
