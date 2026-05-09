return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    -- disable netrw (recommended by nvim-tree)
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    require("nvim-tree").setup({
      view = {
        width = 35,
        preserve_window_proportions = true,
      },
      renderer = {
        indent_markers = { enable = true },
        icons = {
          git_placement = "after",
        },
      },
      git = {
        enable = true,
        ignore = false, -- still show gitignored files, just dimmed
      },
      diagnostics = {
        enable = true,
        show_on_dirs = true,
      },
      filters = {
        dotfiles = false, -- dotfiles visible (we edit them)
        custom = { "^\\.git$" },
      },
      update_focused_file = {
        enable = true,
      },
    })

    vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>", { silent = true })
    vim.keymap.set("n", "<C-t>", ":NvimTreeFindFile<CR>", { silent = true })
  end,
}
