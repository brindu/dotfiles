return {
  "hrsh7th/nvim-cmp",             -- the completion plugin
  "hrsh7th/cmp-buffer",           -- buffer completions
  "hrsh7th/cmp-path",             -- path completions
  "saadparwaiz1/cmp_luasnip",     -- snippet completions
  "hrsh7th/cmp-nvim-lsp",         -- LSP completions
  {
    "L3MON4D3/LuaSnip",             -- snippet engine
    -- jsregexp enables LSP snippet variable/placeholder transformations.
    -- Needs make + a C compiler (Xcode Command Line Tools).
    build = "make install_jsregexp",
    dependencies = {
      "rafamadriz/friendly-snippets", -- a bunch of snippets to use
    },
  },
}
