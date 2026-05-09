-- Debug adapter protocol. Adapters/configurations are language-specific and
-- intentionally not wired up here — add them per-language as needed.
return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
  },
  keys = {
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP: toggle breakpoint" },
    { "<leader>dc", function() require("dap").continue() end,          desc = "DAP: continue" },
    { "<leader>di", function() require("dap").step_into() end,         desc = "DAP: step into" },
    { "<leader>do", function() require("dap").step_over() end,         desc = "DAP: step over" },
    { "<leader>du", function() require("dap").step_out() end,          desc = "DAP: step out" },
    { "<leader>dr", function() require("dap").repl.open() end,         desc = "DAP: open REPL" },
    { "<leader>dt", function() require("dapui").toggle() end,          desc = "DAP: toggle UI" },
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    dapui.setup()

    dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
    dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
    dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
  end,
}
