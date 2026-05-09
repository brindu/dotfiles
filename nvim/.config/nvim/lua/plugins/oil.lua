return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  -- lazy=false so `nvim some/dir` and `-` from any buffer work immediately
  lazy = false,
  config = function()
    require("oil").setup({
      view_options = {
        show_hidden = true,
      },
    })

    vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Oil: open parent directory" })
  end,
}
