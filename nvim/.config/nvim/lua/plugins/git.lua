return {
  {
    "tpope/vim-fugitive",
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()

      vim.keymap.set("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", {})
      vim.keymap.set("n", "<leader>gtb", ":Gitsigns toggle_current_line_blame<CR>", {})
    end,
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewRefresh" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Open diff view (vs HEAD)" },
      { "<leader>gm", "<cmd>DiffviewOpen origin/main<CR>", desc = "Open diff view (vs origin/main)" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history (current file)" },
    },
    config = function()
      require("diffview").setup({})
    end,
  },
}
