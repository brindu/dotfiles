return {
  "Bekaboo/dropbar.nvim",
  event = "VeryLazy",
  config = function()
    require("dropbar").setup({})

    vim.keymap.set("n", "<leader>;", function()
      require("dropbar.api").pick()
    end, { desc = "Dropbar: pick breadcrumb segment" })
  end,
}
