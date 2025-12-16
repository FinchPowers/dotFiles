require("CopilotChat").setup {
  model = "gpt-5",
  sticky = {
        '#files: **,**/*',
  },
}

vim.api.nvim_create_autocmd({"BufWinEnter", "BufWinLeave"}, {
  pattern = "*",
  callback = function()
    if vim.fn.bufname('%'):find('CopilotChat') then
      vim.cmd("silent! TlistUpdate")
      vim.cmd("vertical resize 30") -- set your preferred width
    end
  end
})

require("ibl").setup {
    indent = { char = "┊" },
}


-- Complexity
-- trigger with :ShowComplexity
vim.env.PATH = vim.env.PATH .. ":/Users/fmlheureux/.local/share/nvim/mich-made-venv/.venv-314/bin"
require("complexity").setup{
    thresholds = {
        low = 10, -- CCN <= low is considered low complexity
        medium = 15, -- CCN > low and <= medium is medium complexity
        -- CCN > medium is high complexity
    },

    virt_prefix = "⮕ Complexity:", -- text prefix for virtual text
    virt_pos = "eol", -- extmark position ("eol" or "overlay")

    autosave = false, -- set true to annotate on BufWritePost
    autosave_patterns = { "*.py" }, -- file patterns to trigger autosave
}

-- LSP: typos-lsp (spell checker diagnostics + code actions)
if vim.fn.executable("typos-lsp") == 1 then
  vim.lsp.enable("typos_lsp")
else
  vim.notify("typos-lsp not found in PATH (LSP disabled)", vim.log.levels.WARN)
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
  end,
})

vim.api.nvim_create_autocmd("DiagnosticChanged", {
  group = vim.api.nvim_create_augroup("UnifiedDiagnosticsLocList", { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    if bufnr ~= vim.api.nvim_get_current_buf() then
      return
    end

    local items = vim.diagnostic.get(bufnr)
    local current_win = vim.api.nvim_get_current_win()
    local loc = vim.fn.getloclist(0, { winid = 0 })
    local loclist_open = loc and loc.winid and loc.winid ~= 0

    if #items > 0 then
      vim.diagnostic.setloclist({ open = not loclist_open })
      pcall(vim.api.nvim_set_current_win, current_win)
    else
      if loclist_open then
        pcall(vim.cmd, "lclose")
        pcall(vim.api.nvim_set_current_win, current_win)
      end
    end
  end,
})

-- If the location list (quickfix window) is the only remaining window, quit Neovim.
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = vim.api.nvim_create_augroup("QuitOnOnlyLocList", { clear = true }),
  callback = function()
    if vim.bo.buftype ~= "quickfix" then
      return
    end

    if #vim.api.nvim_tabpage_list_wins(0) ~= 1 then
      return
    end

    vim.schedule(function()
      if vim.bo.buftype == "quickfix" and #vim.api.nvim_tabpage_list_wins(0) == 1 then
        pcall(vim.cmd, "qall")
      end
    end)
  end,
})
