return {
  "hrsh7th/nvim-cmp",             -- The completion plugin
  "hrsh7th/cmp-buffer",           -- buffer completions
  "hrsh7th/cmp-path",             -- path completions
  "hrsh7th/cmp-cmdline",          -- cmdline completions
  "saadparwaiz1/cmp_luasnip",     -- snippet completions
	"hrsh7th/cmp-nvim-lsp",         -- LSP completions
  {
    "L3MON4D3/LuaSnip",             -- snippet engine
    dependencies = {
      "rafamadriz/friendly-snippets", -- a bunch of snippets to use
    },
  },
}
