local M = {}
local running = false

local errorformat = table.concat({
  '%Ee: file://%f:%l:%c: %m',
  '%Ee: file://%f:%l:%c %m',
  '%Ee: %f: (%l\\,%c): %m',
  '%Ee: %f: (%l\\, %c): %m',
  '%Ee: %f:%l:%c: %m',
  '%Ww: file://%f:%l:%c: %m',
  '%Ww: file://%f:%l:%c %m',
  '%Ww: %f: (%l\\,%c): %m',
  '%Ww: %f: (%l\\, %c): %m',
  '%Ww: %f:%l:%c: %m',
  '%-G%.%#',
}, ',')

local function compile_tests()
  if running then
    vim.notify('Gradle test compilation is already running', vim.log.levels.WARN)
    return
  end

  local name = vim.api.nvim_buf_get_name(0)
  local root = (name ~= '' and vim.fs.root(name, 'gradlew')) or vim.fs.root(vim.fn.getcwd(), 'gradlew')
  if not root then
    vim.notify('GradleTestCompile: no gradlew found above the current file or working directory', vim.log.levels.ERROR)
    return
  end

  running = true
  local ok, err = pcall(vim.system, { root .. '/gradlew', '--console=plain', 'compileTestKotlin' }, {
    cwd = root,
    text = true,
  }, function(result)
    vim.schedule(function()
      running = false
      local output = (result.stdout or '') .. '\n' .. (result.stderr or '')
      local lines = vim.split(output, '\n', { trimempty = true })
      local items = vim.fn.getqflist({ lines = lines, efm = errorformat }).items
      -- Keep build failures without compiler locations (e.g. dependency errors) visible too.
      if result.code ~= 0 and #items == 0 then
        for _, line in ipairs(lines) do
          table.insert(items, { text = line })
        end
      end
      vim.fn.setqflist({}, 'r', { title = 'Gradle compileTestKotlin', items = items })
      if #items > 0 then
        vim.cmd.copen()
      end
      if result.code == 0 then
        vim.notify('Gradle test compilation succeeded', vim.log.levels.INFO)
      else
        vim.notify('Gradle test compilation failed (exit ' .. result.code .. '); see quickfix', vim.log.levels.ERROR)
      end
    end)
  end)
  if not ok then
    running = false
    vim.notify('GradleTestCompile: ' .. tostring(err), vim.log.levels.ERROR)
  else
    vim.notify('Compiling Kotlin tests…', vim.log.levels.INFO)
  end
end

function M.setup()
  vim.api.nvim_create_user_command('GradleTestCompile', compile_tests, { desc = 'Compile Kotlin tests asynchronously into quickfix' })
end

return M
