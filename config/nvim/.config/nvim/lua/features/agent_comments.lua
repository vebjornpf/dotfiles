local M = {}
local sending = false

local function notify(text)
  vim.notify(text, vim.log.levels.INFO, { title = 'Agent comments' })
end

local function queue()
  local cwd = vim.uv.cwd()
  local root = vim.fs.root(cwd, '.git') or cwd
  local dir = vim.fn.stdpath 'state' .. '/agent-comments/' .. vim.fn.sha256(root)
  vim.fn.mkdir(dir, 'p')
  local path = root .. '/agent-comments.md'
  local git = vim.system({ 'git', '-C', root, 'rev-parse', '--path-format=absolute', '--git-path', 'info/exclude' }, { text = true }):wait()
  if git.code == 0 then
    local exclude = vim.trim(git.stdout)
    local lines = vim.fn.filereadable(exclude) == 1 and vim.fn.readfile(exclude) or {}
    if not vim.tbl_contains(lines, '/agent-comments.md') then
      vim.fn.mkdir(vim.fs.dirname(exclude), 'p')
      vim.fn.writefile({ '', '/agent-comments.md' }, exclude, 'a')
    end
  end
  -- Preserve an existing queue from the original state-directory location.
  if vim.fn.filereadable(path) == 0 and vim.fn.filereadable(dir .. '/queue.md') == 1 then
    vim.fn.writefile(vim.fn.readfile(dir .. '/queue.md'), path)
    vim.fn.rename(dir .. '/queue.md', dir .. '/migrated-' .. tostring(vim.uv.hrtime()) .. '.md')
  end
  return path, root, dir
end

local function modified(path)
  local buf = vim.fn.bufnr(path)
  return buf ~= -1 and vim.bo[buf].modified
end

local function read(path)
  return vim.fn.filereadable(path) == 1 and table.concat(vim.fn.readfile(path), '\n') or ''
end

-- Store the next ID in the queue so deleting/reordering entries never reuses IDs.
local function assign_ids(path, reserve)
  local lines = vim.fn.readfile(path)
  local entries, counter, next_id, fence = {}, nil, 1, nil
  for index, line in ipairs(lines) do
    local ticks = line:match '^%s*(```+)'
    if ticks then
      if not fence then fence = #ticks
      elseif #ticks >= fence and line:match '^%s*`+%s*$' then fence = nil end
    elseif not fence then
      local stored = line:match '^<!%-%- next%-comment%-id: (%d+) %-%->$'
      if stored then
        counter = index
        next_id = math.max(next_id, tonumber(stored))
      end
      local id = line:match '^## C(%d+) — .+:%d+%-%d+$'
      local legacy = line:match '^## (.+:%d+%-%d+)$'
      if id then
        next_id = math.max(next_id, tonumber(id) + 1)
      elseif legacy then
        entries[#entries + 1] = { index = index, location = legacy }
      end
    end
  end
  for _, entry in ipairs(entries) do
    lines[entry.index] = '## C' .. next_id .. ' — ' .. entry.location
    next_id = next_id + 1
  end
  local metadata = '<!-- next-comment-id: ' .. (next_id + (reserve and 1 or 0)) .. ' -->'
  if counter then lines[counter] = metadata else table.insert(lines, 2, metadata) end
  if table.concat(lines, '\n') ~= read(path) then
    vim.fn.writefile(lines, path)
    local buf = vim.fn.bufnr(path)
    if buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].modified = false
    end
  end
  return next_id
end

local reply_instructions = [[

---
# Reply instructions

Respond to each comment separately, in queue order, using its exact ID (C1, C2, etc.).
Use a heading such as "C2 — src/auth.lua:61-63" so I can reference it in follow-ups.
Under each heading:
- Briefly quote or restate my comment.
- Answer directly in plain language. Treat questions as questions, not automatic requests to change code.
- For requested changes, explain what changed and how you verified it; say if verification was not performed.
- State any ambiguity or decision you need from me explicitly; do not silently guess.
Keep explanations concise but understandable. Do not combine answers to different IDs.
Finish with unresolved questions or decisions, labeled with their comment IDs, only if any remain.
Code and line numbers are snapshots: check the current files before making changes.
]]

local function run(args, callback, timeout)
  vim.system(args, { text = true, timeout = timeout or 15000 }, vim.schedule_wrap(callback))
end

local function start_agent(root, workspace, panes, callback)
  local function fail(message)
    sending = false
    notify(message .. ' Queue retained; any created tab/pane was left open for inspection.')
  end
  local function request(args, done, timeout)
    run(args, function(result)
      if result.code ~= 0 then return fail('Herdr setup failed: ' .. (result.stderr or '')) end
      local ok, data = pcall(vim.json.decode, result.stdout)
      if not ok or not data.result then return fail 'Invalid Herdr setup response.' end
      done(data.result)
    end, timeout)
  end
  local function launch(pane)
    if not pane or not pane.pane_id then return fail 'Herdr did not return a new pane.' end
    local name = 'comments-' .. tostring(vim.uv.hrtime())
    notify('Starting OpenCode in ' .. pane.pane_id .. '…')
    request({ 'herdr', 'agent', 'start', name, '--kind', 'opencode', '--pane', pane.pane_id, '--timeout', '30000' }, function()
      callback({ agent = 'opencode', pane_id = pane.pane_id })
    end, 45000)
  end
  request({ 'herdr', 'workspace', 'get', workspace }, function(info)
    local label = info.workspace and info.workspace.label
    if not label or label == '' then return fail 'The Herdr workspace needs a name first.' end
    request({ 'herdr', 'tab', 'list', '--workspace', workspace }, function(list)
      if type(list.tabs) ~= 'table' then return fail 'Herdr did not return a tab list.' end
      for _, tab in ipairs(list.tabs) do
        if tab.label == label then
          for _, pane in ipairs(panes) do
            if pane.tab_id == tab.tab_id then
              return request({ 'herdr', 'pane', 'split', pane.pane_id, '--direction', 'right', '--cwd', root, '--no-focus' }, function(split)
                launch(split.pane)
              end)
            end
          end
          return fail 'The workspace-named tab has no available pane to split.'
        end
      end
      request({ 'herdr', 'tab', 'create', '--workspace', workspace, '--label', label, '--cwd', root, '--no-focus' }, function(created)
        launch(created.root_pane)
      end)
    end)
  end)
end

function M.add()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' or vim.bo.buftype ~= '' then return notify 'Select code in a named file first.' end
  local path, root = queue()
  local first, last = vim.fn.line 'v', vim.fn.line '.'
  local code = vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', { type = vim.fn.mode() })
  local language = vim.bo.filetype
  local location = (vim.fs.relpath(root, file) or file) .. ':' .. math.min(first, last) .. '-' .. math.max(first, last)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
  vim.ui.input({ prompt = 'Comment: ' }, function(comment)
    if not comment or comment:match '^%s*$' then return end
    if sending or modified(path) then return notify 'Save the queue and wait for any send to finish first.' end
    local fence = '```'
    for _, line in ipairs(code) do
      for ticks in line:gmatch '`+' do
        if #ticks >= #fence then fence = string.rep('`', #ticks + 1) end
      end
    end
    if read(path):match '^%s*$' then
      vim.fn.writefile({ '# Code comments', '', 'Please address these comments. Code and line numbers are captured snapshots.' }, path)
    end
    local id = assign_ids(path, true)
    local entry = { '', '## C' .. id .. ' — ' .. location, '', fence .. language }
    vim.list_extend(entry, code)
    vim.list_extend(entry, { fence, '', '**Comment:** ' .. comment, '' })
    vim.fn.writefile(entry, path, 'a')
    vim.cmd 'checktime'
    notify('Added C' .. id .. ': ' .. location)
  end)
end

function M.open()
  local path = queue()
  if not modified(path) and not read(path):match '^%s*$' then assign_ids(path) end
  vim.cmd.edit(vim.fn.fnameescape(path))
end

function M.flush()
  if sending then return notify 'Wait for the current send to finish before flushing.' end
  local path = queue()
  if modified(path) then return notify 'Save the queue with :w before flushing.' end
  if vim.fn.confirm('Flush all queued agent comments?', '&Flush\n&Cancel', 2) ~= 1 then return end
  vim.fn.writefile({}, path)
  local buf = vim.fn.bufnr(path)
  if buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    vim.bo[buf].modified = false
  end
  notify 'Comment queue flushed.'
end

function M.send()
  if sending then return notify 'A send is already in progress.' end
  if vim.env.HERDR_ENV ~= '1' or not vim.env.HERDR_WORKSPACE_ID or vim.fn.executable 'herdr' ~= 1 then
    return notify 'Run Neovim inside Herdr with herdr on PATH to send comments.'
  end
  local path, root, archive_dir = queue()
  local workspace = vim.env.HERDR_WORKSPACE_ID
  if modified(path) then return notify 'Save the queue with :w before sending.' end
  if not read(path):match '^%s*$' then assign_ids(path) end
  local text = read(path)
  if text:match '^%s*$' then return notify 'No queued comments.' end
  run({ 'herdr', 'pane', 'list', '--workspace', workspace }, function(result)
    if result.code ~= 0 then return notify('Cannot list agents: ' .. (result.stderr or '')) end
    local ok, data = pcall(vim.json.decode, result.stdout)
    if not ok or not data.result or type(data.result.panes) ~= 'table' then return notify 'Invalid Herdr response.' end
    local agents = vim.tbl_filter(function(pane) return type(pane.agent) == 'string' end, data.result.panes)
    table.insert(agents, 1, { new = true })
    require('features.agent_picker').select(agents, function(agent)
      if not agent then return end
      if agent.agent_status == 'blocked' then return notify 'Agent is blocked; answer its pending question first.' end
      if agent.new and vim.fn.executable 'opencode' ~= 1 then return notify 'opencode is not on PATH.' end
      if sending or modified(path) or read(path) ~= text then return notify 'Queue changed; check it and send again.' end
      sending = true
      local function deliver(target_agent)
        agent = target_agent
        if modified(path) or read(path) ~= text then
          sending = false
          return notify 'Queue changed during agent startup; retained without sending. Check it and send again.'
        end
        local prompt = text .. reply_instructions
        run({ 'herdr', 'agent', 'prompt', agent.pane_id, prompt }, function(sent)
          sending = false
          if sent.code ~= 0 then
            return notify('Send failed or uncertain; queue retained. Check the agent before retrying. ' .. (sent.stderr or ''))
          end
          local archive = archive_dir .. '/sent-' .. os.date '%Y%m%d-%H%M%S' .. '-' .. tostring(vim.uv.hrtime()) .. '.md'
          local contents = vim.split(prompt, '\n', { plain = true })
          vim.list_extend(contents, { '', '---', 'Sent to ' .. agent.pane_id .. ' (' .. agent.agent .. ') at ' .. os.date '%Y-%m-%d %H:%M:%S' })
          vim.fn.writefile(contents, archive)
          notify('Herdr accepted the prompt. Queue retained; Space a f flushes it. Archived: ' .. archive)
        end)
      end
      if agent.new then
        start_agent(root, workspace, data.result.panes, deliver)
      else
        deliver(agent)
      end
    end)
  end)
end

function M.setup()
  vim.keymap.set('x', '<leader>ac', M.add, { desc = 'Agent: comment on selection' })
  vim.keymap.set('n', '<leader>aq', M.open, { desc = 'Agent: open comment queue' })
  vim.keymap.set('n', '<leader>as', M.send, { desc = 'Agent: send comment queue' })
  vim.keymap.set('n', '<leader>af', M.flush, { desc = 'Agent: flush comment queue' })
end

return M
