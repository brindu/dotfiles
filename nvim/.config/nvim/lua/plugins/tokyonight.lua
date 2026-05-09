return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    -- Variants: "storm" (default — bluish dark), "night" (darkest), "moon" (warmer dark), "day" (light)
    style = "night",
    transparent = false,
    terminal_colors = true,
    styles = {
      sidebars = "dark",
      floats = "dark",
    },
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight")
  end,
}
