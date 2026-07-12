-- nvim-treesitter `main` branch.
--
-- On `main` the plugin only installs parsers and ships queries. Highlighting,
-- indent and folds are driven by Neovim core (`vim.treesitter.*`) rather than a
-- `configs.setup {}` module table -- there is no `highlight.enable`,
-- `auto_install` or `ensure_installed`. Neovim 0.12 dropped support for the
-- frozen `master` branch, which is why we live here now.
local parsers = {
  -- core / runtime
  "bash",
  "lua",
  "vim",
  "vimdoc",
  "query",
  "regex",
  "comment",
  -- web frontend
  "javascript",
  "typescript",
  "tsx",
  "html",
  "css",
  "scss",
  "json",
  -- backend / Rails
  "ruby",
  "embedded_template", -- ERB
  "python",
  -- config / infra
  "yaml",
  "toml",
  "dockerfile",
  -- data
  "sql",
  "csv",
  -- git
  "git_config",
  "git_rebase",
  "gitcommit",
  "gitignore",
  "diff",
}
-- markdown is intentionally absent: its upstream queries reference grammar nodes
-- the shipped parser lacks, which crashes the core highlighter. With it
-- uninstalled, the pcall below simply skips markdown buffers.

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local nts = require("nvim-treesitter")

      -- Compile/update the parsers above into stdpath("data")/site. Async and
      -- idempotent: a no-op once each parser is already at the pinned revision.
      nts.install(parsers)

      -- `main` dropped `auto_install`; this restores it. Cache the installed
      -- and available parser sets once, then on each FileType:
      --   * installed  -> start core highlighting;
      --   * available  -> fetch the parser async, start highlighting when it
      --                   lands (optimistically marked installed so we never
      --                   kick off a duplicate install);
      --   * neither    -> leave it to default syntax.
      -- pcall keeps filetypes without a parser (markdown, etc.) from erroring.
      local installed, available = {}, {}
      for _, l in ipairs(nts.get_installed("parsers")) do installed[l] = true end
      for _, l in ipairs(nts.get_available()) do available[l] = true end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true }),
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          if ft == "" then return end
          local lang = vim.treesitter.language.get_lang(ft) or ft

          if installed[lang] then
            pcall(vim.treesitter.start, args.buf)
          elseif available[lang] then
            installed[lang] = true
            nts.install(lang):await(vim.schedule_wrap(function(err)
              if not err and vim.api.nvim_buf_is_valid(args.buf) then
                pcall(vim.treesitter.start, args.buf)
              end
            end))
          end
        end,
      })
    end,
    dependencies = {
      -- endwise's default branch targets the frozen master module API; this
      -- branch uses the stable core treesitter APIs and works with `main`.
      { "RRethy/nvim-treesitter-endwise", branch = "refactor/migrate-to-stable-treesitter-api" },
    },
  },
}
