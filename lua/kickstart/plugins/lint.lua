---@module 'lazy'
---@type LazySpec
return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      -- Lint through the eslint_d daemon rather than spawning a fresh `eslint`
      -- each time. Configs that turn on type-aware linting (`projectService`)
      -- make every cold start build a whole TypeScript program, which in a
      -- large monorepo costs ~20s and several GB of RSS. The daemon pays that
      -- once and then answers in ~200ms.
      local eslint_d = vim.tbl_extend('force', {}, lint.linters.eslint_d)

      -- `eslint-plugin-file-progress` writes a progress spinner to stdout,
      -- where it lands in the middle of the JSON report. Its `recommended-ci`
      -- config stays quiet when CI is set. `env` replaces the environment
      -- wholesale, so extend the real one instead of passing CI on its own.
      eslint_d.env = vim.tbl_extend('force', vim.fn.environ(), { CI = 'true' })

      -- The first request after the daemon starts can still print resolver
      -- warnings ahead of the report, so parse from the start of the JSON.
      local eslint_parser = lint.linters.eslint.parser
      eslint_d.parser = function(output, bufnr, linter_cwd)
        local json_start = output:find('[', 1, true)
        if not json_start then return {} end
        return eslint_parser(output:sub(json_start), bufnr, linter_cwd)
      end

      lint.linters.eslint_d = eslint_d

      lint.linters_by_ft = {
        --      markdown = { 'markdownlint' },
        typescript = { 'eslint_d' },
        typescriptreact = { 'eslint_d' },
      }

      -- To allow other plugins to add linters to require('lint').linters_by_ft,
      -- instead set linters_by_ft like this:
      -- lint.linters_by_ft = lint.linters_by_ft or {}
      -- lint.linters_by_ft['markdown'] = { 'markdownlint' }
      --
      -- However, note that this will enable a set of default linters,
      -- which will cause errors unless these tools are available:
      -- {
      --   clojure = { "clj-kondo" },
      --   dockerfile = { "hadolint" },
      --   inko = { "inko" },
      --   janet = { "janet" },
      --   json = { "jsonlint" },
      --   markdown = { "vale" },
      --   rst = { "vale" },
      --   ruby = { "ruby" },
      --   terraform = { "tflint" },
      --   text = { "vale" }
      -- }
      --
      -- You can disable the default linters by setting their filetypes to nil:
      -- lint.linters_by_ft['clojure'] = nil
      -- lint.linters_by_ft['dockerfile'] = nil
      -- lint.linters_by_ft['inko'] = nil
      -- lint.linters_by_ft['janet'] = nil
      -- lint.linters_by_ft['json'] = nil
      -- lint.linters_by_ft['markdown'] = nil
      -- lint.linters_by_ft['rst'] = nil
      -- lint.linters_by_ft['ruby'] = nil
      -- lint.linters_by_ft['terraform'] = nil
      -- lint.linters_by_ft['text'] = nil

      -- Collapse bursts of events into a single run. nvim-lint neither
      -- debounces nor cancels a run already in flight, so without this every
      -- event starts another process alongside the ones still working.
      local timer = assert(vim.uv.new_timer())
      local function debounced_lint()
        timer:stop()
        timer:start(
          300,
          0,
          vim.schedule_wrap(function()
            -- Only run the linter in buffers that you can modify in order to
            -- avoid superfluous noise, notably within the handy LSP pop-ups that
            -- describe the hovered symbol using Markdown.
            if vim.bo.modifiable then lint.try_lint() end
          end)
        )
      end

      -- Create autocommand which carries out the actual linting
      -- on the specified events.
      --
      -- Deliberately not on InsertLeave: every i/<Esc> would queue another
      -- lint. BufReadPost rather than BufEnter, so switching windows between
      -- buffers already open does not re-lint them.
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' }, {
        group = lint_augroup,
        callback = debounced_lint,
      })
    end,
  },
}
