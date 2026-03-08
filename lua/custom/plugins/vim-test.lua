return {
  'vim-test/vim-test',
  dependencies = {
    'preservim/vimux',
  },
  config = function()
    vim.keymap.set('n', '<leader>rt', ':TestNearest<CR>')
    vim.keymap.set('n', '<leader>rT', ':TestFile<CR>')
    vim.keymap.set('n', '<leader>ra', ':TestSuite<CR>')
    vim.keymap.set('n', '<leader>rl', ':TestLast<CR>')
    vim.keymap.set('n', '<leader>rg', ':TestVisit<CR>')
    vim.cmd "let test#strategy = 'vimux'"

    local group = vim.api.nvim_create_augroup('SbProject', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufRead' }, {
      group = group,
      pattern = '/Users/marks/Development/qnr-server/apps/chrome-extension/**/*',
      callback = function()
        -- config for vitest
        -- vim.cmd "let test#project_root = '/Users/marks/Development/qnr-server/apps/chrome-extension'"
        vim.cmd "let g:test#javascript#runner = 'vitest'"
      end,
    })

    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufRead' }, {
      group = group,
      pattern = '/Users/marks/Development/qnr-server/apps/server/**/*',
      callback = function()
        -- config for jest
        --vim.cmd "let test#project_root = '/Users/marks/Development/qnr-server/apps/server'"
        vim.cmd "let g:test#javascript#runner = 'jest'"
      end,
    })
  end,
}
