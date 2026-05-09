-- :help options for full documentation
vim.opt.backup = false            -- creates a backup file
vim.opt.clipboard = "unnamedplus" -- allows neovim to access the system clipboard
vim.opt.cmdheight = 2             -- more space in the neovim command line for displaying messages
vim.opt.completeopt = { 					-- mostly just for cmp
	"menuone",
	"noselect",
}
vim.opt.conceallevel = 0          -- so that `` is visible in markdown files
vim.opt.fileencoding = "utf-8"    -- the encoding written to a file
vim.opt.hlsearch = true           -- highlight all matches on previous search pattern
vim.opt.ignorecase = true         -- ignore case in search patterns
vim.opt.pumheight = 10            -- pop up menu height
vim.opt.showtabline = 2           -- always show tabs
vim.opt.smartcase = true          -- smart case
vim.opt.smartindent = true        -- make indenting smarter again
vim.opt.splitbelow = true         -- force all horizontal splits to go below current window
vim.opt.splitright = true         -- force all vertical splits to go to the right of current window
vim.opt.swapfile = false          -- creates a swapfile
vim.opt.termguicolors = true      -- set term gui colors (most terminals support this)
vim.opt.timeoutlen = 1000         -- time to wait for a mapped sequence to complete (in milliseconds)
vim.opt.undofile = true           -- enable persistent undo
vim.opt.updatetime = 300          -- faster completion (4000ms default)
vim.opt.writebackup = false       -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
vim.opt.expandtab = true          -- convert tabs to spaces
vim.opt.shiftwidth = 2            -- the number of spaces inserted for each indentation
vim.opt.tabstop = 2               -- insert 2 spaces for a tab
vim.opt.cursorline = true         -- highlight the current line
vim.opt.number = true             -- set numbered lines
vim.opt.relativenumber = false    -- set relative numbered lines
vim.opt.numberwidth = 3           -- set number column width  {default 4}
vim.opt.signcolumn = "yes"        -- always show the sign column, otherwise it would shift the text each time
vim.opt.wrap = false              -- display lines as one long line
vim.opt.scrolloff = 8             -- min number of lines to keep above and below cursor
vim.opt.sidescrolloff = 8

vim.opt.shortmess:append "c"

vim.opt.history = 1000    -- big phat history
vim.opt.ruler = true      -- show the cursor position all the time
vim.opt.showcmd = true    -- display incomplete commands
vim.opt.incsearch = true  -- do incremental searching
vim.opt.laststatus = 2    -- Always display the status line
vim.opt.gdefault = true   -- subtitutions globally on lines
vim.opt.showmode = true   -- Show current mode down the bottom
-- vim.opt.visualbell = true -- No sounds

-- Softtabs, 2 spaces
 vim.opt.autoindent = true
-- vim.opt.smarttab = true
-- vim.opt.softtabstop = 2
-- vim.opt.backspace = '2'

vim.opt.guicursor = "n-v-i-c:block-Cursor" -- Block cursor style for all mode

-- Remove trailing whitespace on save
vim.cmd([[autocmd BufWritePre * :%s/\s\+$//e]])

vim.cmd "set whichwrap+=<,>,[,],h,l"
vim.cmd [[set iskeyword+=-]]

