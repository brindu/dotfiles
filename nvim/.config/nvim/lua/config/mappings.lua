local opts = { silent = true }

-- Remap space as leader
vim.keymap.set("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Easy split navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
vim.keymap.set("n", "<C-j>", "<C-w>j", opts)
vim.keymap.set("n", "<C-k>", "<C-w>k", opts)
vim.keymap.set("n", "<C-l>", "<C-w>l", opts)

-- Resize splits
vim.keymap.set("n", "<leader>[", ":resize +2<CR>", opts)
vim.keymap.set("n", "<leader>]", ":resize -2<CR>", opts)
vim.keymap.set("n", "<leader>=", ":vertical resize -2<CR>", opts)
vim.keymap.set("n", "<leader>-", ":vertical resize +2<CR>", opts)

-- Buffer navigation: <S-h>/<S-l> are owned by bufferline.nvim (BufferLineCyclePrev/Next)

-- Visual: stay in indent mode after shifting
vim.keymap.set("v", "<", "<gv", opts)
vim.keymap.set("v", ">", ">gv", opts)

-- Visual: move text up/down, paste without yanking replaced text
vim.keymap.set("v", "<leader>,", ":m .+1<CR>==", opts)
vim.keymap.set("v", "<leader>.", ":m .-2<CR>==", opts)
vim.keymap.set("v", "p", '"_dP', opts)
