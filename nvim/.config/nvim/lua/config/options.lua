-- :help options for full documentation
vim.opt.clipboard = "unnamedplus" -- allows neovim to access the system clipboard
vim.opt.cmdheight = 2             -- more space in the command line for messages
vim.opt.completeopt = {           -- mostly just for cmp
  "menuone",
  "noselect",
}
vim.opt.conceallevel = 0          -- so that `` is visible in markdown files
vim.opt.ignorecase = true         -- ignore case in search patterns
vim.opt.pumheight = 10            -- pop up menu height
vim.opt.showtabline = 2           -- always show the tabline
vim.opt.smartcase = true          -- override ignorecase when uppercase is present
vim.opt.smartindent = true        -- smart auto-indent on new lines
vim.opt.splitbelow = true         -- horizontal splits go below current window
vim.opt.splitright = true         -- vertical splits go to the right of current window
vim.opt.swapfile = false          -- no swapfiles
vim.opt.termguicolors = true      -- 24-bit colors
vim.opt.undofile = true           -- persistent undo across sessions
vim.opt.updatetime = 300          -- faster CursorHold (default 4000ms)
vim.opt.writebackup = false       -- don't refuse to edit files being written by another program
vim.opt.expandtab = true          -- convert tabs to spaces
vim.opt.shiftwidth = 2            -- spaces per indent level
vim.opt.tabstop = 2               -- spaces per <Tab>
vim.opt.cursorline = true         -- highlight the current line
vim.opt.number = true             -- show line numbers
vim.opt.numberwidth = 3           -- number column width (default 4)
vim.opt.signcolumn = "yes"        -- always show the sign column
vim.opt.wrap = false              -- no soft-wrap
vim.opt.scrolloff = 8             -- keep 8 lines visible above/below cursor
vim.opt.sidescrolloff = 8
vim.opt.gdefault = true           -- :s substitutes are global by default
vim.opt.autoindent = true

vim.opt.shortmess:append("c")
vim.opt.whichwrap:append("<,>,[,],h,l")
vim.opt.iskeyword:append("-")

vim.opt.guicursor = "n-v-i-c:block-Cursor" -- block cursor in all modes

-- Trim trailing whitespace on save without clobbering cursor or search register
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})
