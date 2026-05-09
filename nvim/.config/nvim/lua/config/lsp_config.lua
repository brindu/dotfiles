require("mason").setup()

-- Apply cmp completion capabilities to every LSP server. mason-lspconfig's
-- automatic_enable will call vim.lsp.enable() for each installed server,
-- which picks up this shared config.
local capabilities = require("cmp_nvim_lsp").default_capabilities()
vim.lsp.config("*", { capabilities = capabilities })

require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "ruby_lsp" },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local opts = { buffer = bufnr, silent = true }
    local builtin = require("telescope.builtin")

    -- Navigation (Telescope pickers — overrides 0.11 grr/gri/grt defaults)
    vim.keymap.set("n", "gd", builtin.lsp_definitions, opts)
    vim.keymap.set("n", "gr", builtin.lsp_references, opts)
    vim.keymap.set("n", "gi", builtin.lsp_implementations, opts)
    vim.keymap.set("n", "gy", builtin.lsp_type_definitions, opts)

    -- Refactoring
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>F", function()
      vim.lsp.buf.format({ async = true })
    end, opts)

    -- Diagnostics (jump keys [d/]d are 0.11 defaults)
    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)

    -- Highlight symbol under cursor when supported. Done last so a missing
    -- args.data or absent client can't strand the keymaps above.
    local client = args.data and vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.server_capabilities.documentHighlightProvider then
      vim.cmd([[
        hi! LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
        hi! LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
        hi! LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
      ]])
      local hl_group = vim.api.nvim_create_augroup("user-lsp-highlight-" .. bufnr, { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = hl_group,
        buffer = bufnr,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = hl_group,
        buffer = bufnr,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})
