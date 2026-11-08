local M = {}
local comparison_base = 'index'
local comparison_ref
local base_request = 0

function M.base_label()
  return 'Base: ' .. comparison_base
end

function M.base_ref()
  return comparison_ref
end

local function change_base(base, label)
  base_request = base_request + 1
  require('gitsigns').change_base(base, true, vim.schedule_wrap(function(err)
    if err then
      vim.notify('Could not change Git comparison base: ' .. tostring(err), vim.log.levels.ERROR)
      return
    end
    comparison_base = label or base or 'index'
    comparison_ref = base
    vim.cmd.redrawstatus()
  end))
end

local function change_pr_base()
  base_request = base_request + 1
  local request = base_request
  local cwd = vim.fn.getcwd()
  for _, executable in ipairs { 'gh', 'git' } do
    if vim.fn.executable(executable) == 0 then
      vim.notify('GitBasePR requires ' .. executable .. ' on PATH', vim.log.levels.ERROR)
      return
    end
  end

  local function run(args, callback)
    vim.system(args, { cwd = cwd, text = true, timeout = 15000 }, vim.schedule_wrap(function(result)
      if request ~= base_request then
        return
      end
      callback(result)
    end))
  end

  local function find_pr(selector)
    local args = { 'gh', 'pr', 'view' }
    if selector then
      args[#args + 1] = selector
    end
    vim.list_extend(args, { '--json', 'baseRefName,baseRefOid' })
    run(args, function(result)
      if result.code ~= 0 then
        vim.notify('Could not find the current PR. Check gh authentication and the checked-out branch.\n'
          .. vim.trim(result.stderr or ''), vim.log.levels.ERROR)
        return
      end
      local ok, pr = pcall(vim.json.decode, result.stdout)
      if not ok or type(pr) ~= 'table' or type(pr.baseRefName) ~= 'string'
        or type(pr.baseRefOid) ~= 'string' or not pr.baseRefOid:match('^%x+$') then
        vim.notify('Could not read the PR target from gh', vim.log.levels.ERROR)
        return
      end

      run({ 'git', 'merge-base', 'HEAD', pr.baseRefOid }, function(merge_base)
        if merge_base.code ~= 0 or vim.trim(merge_base.stdout or '') == '' then
          vim.notify('Could not resolve the PR merge base. Fetch the target branch (' .. pr.baseRefName
            .. ') from its upstream remote first; shallow clones may need more history.\n'
            .. vim.trim(merge_base.stderr or ''), vim.log.levels.ERROR)
          return
        end
        change_base(vim.trim(merge_base.stdout), 'PR (' .. pr.baseRefName .. ')')
      end)
    end)
  end

  run({ 'git', 'symbolic-ref', '--quiet', '--short', 'HEAD' }, function(result)
    if result.code ~= 0 then
      vim.notify('GitBasePR requires a checked-out PR branch (HEAD is detached)', vim.log.levels.ERROR)
      return
    end
    local branch = vim.trim(result.stdout)
    local number = branch:match('^pr%-(%d+)$')
    if number then
      find_pr(number)
      return
    end
    run({ 'git', 'config', '--get', 'branch.' .. branch .. '.merge' }, function(upstream)
      local head_branch = upstream.code == 0 and vim.trim(upstream.stdout):match('^refs/heads/(.+)$') or nil
      find_pr(head_branch or branch)
    end)
  end)
end

function M.setup_commands()
  vim.api.nvim_create_user_command('ToggleFileBlame', function()
    require('features.git_blame').toggle()
  end, { desc = 'Toggle whole-file Git blame' })

  vim.api.nvim_create_user_command('ToggleLineBlame', function()
    require('features.git_blame').toggle_line()
  end, { desc = 'Toggle inline Git blame for the current line' })

  vim.api.nvim_create_user_command('GitBasePR', change_pr_base,
    { desc = 'Compare all buffers against the current PR merge base' })

  vim.api.nvim_create_user_command('GitBaseMain', function()
    change_base 'main'
  end, { desc = 'Compare all buffers against local main' })

  vim.api.nvim_create_user_command('GitBaseOriginMain', function()
    change_base 'origin/main'
  end, { desc = 'Compare all buffers against cached origin/main' })

  vim.api.nvim_create_user_command('GitBaseReset', function()
    change_base(nil)
  end, { desc = 'Reset all buffers to the Git index comparison' })
end

function M.gitsigns_on_attach(bufnr)
  local gs = package.loaded.gitsigns

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  map('n', '<leader>hn', function()
    if vim.wo.diff then
      vim.cmd.normal { ']c', bang = true }
    else
      gs.nav_hunk 'next'
    end
  end, 'Jump to next hunk')

  map('n', '<leader>hN', function()
    if vim.wo.diff then
      vim.cmd.normal { '[c', bang = true }
    else
      gs.nav_hunk 'prev'
    end
  end, 'Jump to previous hunk')

  map('n', '<leader>hs', gs.stage_hunk, 'Stage hunk')
  map('v', '<leader>hs', function() gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, 'Stage hunk')
  map('n', '<leader>hr', gs.reset_hunk, 'Reset hunk')
  map('v', '<leader>hr', function() gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, 'Reset hunk')
  map('n', '<leader>hS', gs.stage_buffer, 'Stage buffer')
  map('n', '<leader>hu', gs.undo_stage_hunk, 'Undo stage hunk')
  map('n', '<leader>hR', gs.reset_buffer, 'Reset buffer')
  map('n', '<leader>hp', gs.preview_hunk_inline, 'Preview hunk')
  map('n', '<leader>hb', function() gs.blame_line { full = true } end, 'Blame line')
  map('n', '<leader>hB', function() require('features.git_blame').toggle() end, 'Toggle file blame')
  map('n', '<leader>hl', function() require('features.git_blame').toggle_line() end, 'Toggle inline line blame')
  map('n', '<leader>hd', function() require('features.git_diff').toggle() end, 'Toggle Git comparison')
  map('n', '<leader>hD', function() gs.diffthis('~', { vertical = true }) end, 'Diff against index')
end

function M.diffview_keys()
  return {
    { '<leader>gd', function()
      local base = M.base_ref()
      vim.cmd('DiffviewOpen' .. (base and ' ' .. vim.fn.fnameescape(base) or ''))
    end, desc = '[G]it [D]iff: active Gitsigns base' },
    { '<leader>gb', '<cmd>DiffviewOpen main...HEAD<CR>', desc = '[G]it [B]ranch diff: commits since main' },
    { '<leader>gH', '<cmd>DiffviewFileHistory %<CR>', desc = '[G]it file [H]istory' },
    { '<leader>gD', '<cmd>DiffviewClose<CR>', desc = '[G]it close [D]iff view' },
  }
end

return M
