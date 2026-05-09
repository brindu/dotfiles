return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "olimorris/neotest-rspec",
  },
  keys = {
    { "<leader>tn", function() require("neotest").run.run() end, desc = "Test nearest" },
    { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Test file" },
    { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Test last" },
    { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle test summary" },
    { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Open test output" },
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-rspec"),
      },
    })
  end,
}
