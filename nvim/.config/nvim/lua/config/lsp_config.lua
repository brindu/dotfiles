require("mason").setup({})
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "solargraph" }
})

local on_attach = function(client, bufnr)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})

  -- Highlight symbol under cursor
  if client.server_capabilities.documentHighlightProvider then
    vim.cmd [[
    hi! LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
    hi! LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
    hi! LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
    ]]
    vim.api.nvim_create_augroup('lsp_document_highlight', {
      clear = false
    })
    vim.api.nvim_clear_autocmds({
      buffer = bufnr,
      group = 'lsp_document_highlight',
    })
    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      group = 'lsp_document_highlight',
      buffer = bufnr,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      group = 'lsp_document_highlight',
      buffer = bufnr,
      callback = vim.lsp.buf.clear_references,
    })
  end
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("lspconfig").solargraph.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

require("lspconfig").lua_ls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
