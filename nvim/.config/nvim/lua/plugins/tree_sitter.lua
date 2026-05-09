return {
  "nvim-treesitter/nvim-treesitter",
  config = function()
    require("nvim-treesitter.configs").setup {
      -- A list of parser names
      ensure_installed = {
        "bash",
        "javascript",
        "json",
        "lua",
        "python",
        "css",
        "scss",
        "ruby",
        "yaml",
        "dockerfile",
        "git_config",
        "git_rebase",
        "gitcommit",
        "html",
      },

      -- Install parsers synchronously (only applied to `ensure_installed`)
      sync_install = false,
      auto_install = true,
      highlight = {
        enable = true,
        disable = { "markdown" },
      },
      endwise = {
        enable = true,
      },
      indent = {
        enable = false,
      }
    }
  end,
  dependencies = { "RRethy/nvim-treesitter-endwise" }
}
